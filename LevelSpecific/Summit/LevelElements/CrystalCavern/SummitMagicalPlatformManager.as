struct FSummitMagicMoveablePlatforms
{
	UPROPERTY(EditAnywhere)
	AActor Platform;
	UPROPERTY(EditAnywhere)
	AActor OriginalPlatform;

	FHazeAcceleratedVector AccelLoc;
	FHazeAcceleratedRotator AccelRot;
	FVector TargetLoc;
	FRotator TargetRot;

	FVector StartPosition;
	FQuat StartQuat;
	FVector EndPosition;
	FQuat EndQuat;
	float CurrentDuration = 0.0;
	float AddedTime;
	float ZCurrentOffset = 0.0;
	bool bIsMoving;
	bool bOverlayMaterialActive;
	bool bCanWalkOn;
	UNiagaraComponent TrailComp;
}

class ASummitMagicalPlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	float MoveDuration = 0.35;
	float DelayAdd = 0.15;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve ZOffsetCurve;
	default ZOffsetCurve.AddDefaultKey(0.0, 0.0);
	default ZOffsetCurve.AddDefaultKey(0.9, -1.0);
	default ZOffsetCurve.AddDefaultKey(1.0, 0.0);

	float ZOffset = 1000.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve RotateCurve;
	default RotateCurve.AddDefaultKey(0.0, 0.0);
	default RotateCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	ADeathVolume DeathVolume;

	UPROPERTY(EditInstanceOnly)
	ASummitAcidActivatorStatueFlamer AcidActivator;

	UPROPERTY(EditAnywhere)
	TArray<FSummitMagicMoveablePlatforms> PlatformData;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem PlatformTrailEffect;

	bool bActive;
	bool bCanStartMovingBack;

	FHazeAcceleratedFloat AccelMoveAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathVolume.DisableDeathVolume(this);
		AcidActivator.OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");
		AcidActivator.OnAcidActorDeactivated.AddUFunction(this, n"OnAcidActorDeactivated");

		Network::SetActorControlSide(this, Game::Zoe);

		float DelayAddTotal = 0.0;

		for (FSummitMagicMoveablePlatforms& Data : PlatformData)
		{
			Data.StartPosition = Data.OriginalPlatform.ActorLocation;
			Data.StartQuat = Data.OriginalPlatform.ActorRotation.Quaternion();
			Data.EndPosition = Data.Platform.ActorLocation;
			Data.EndQuat = Data.Platform.ActorRotation.Quaternion();
			Data.AddedTime = DelayAddTotal;
			DelayAddTotal += DelayAdd;

			Data.Platform.ActorLocation = Data.StartPosition;
			Data.Platform.ActorRotation = Data.StartQuat.Rotator();
			Data.AccelLoc.SnapTo(Data.Platform.ActorLocation);
			Data.AccelRot.SnapTo(Data.Platform.ActorRotation);
			Data.TrailComp = Data.Platform.GetOrCreateComponent(UNiagaraComponent);
			Data.TrailComp.Asset = PlatformTrailEffect;
			Data.TrailComp.Deactivate();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			for (FSummitMagicMoveablePlatforms& Data : PlatformData)
			{
				if (Data.CurrentDuration == 0.0 && !Data.bIsMoving)
				{
					Data.bIsMoving = true;
					Data.bOverlayMaterialActive = true;
					USummitMagicalPlatformManagerEventHandler::Trigger_StartMoving(this, FSummitMagicalPlatformStartMoveParams(Data.Platform, Data.TrailComp, Data.Platform.GetComponentByClass(UStaticMeshComponent)));
				}

				Data.CurrentDuration += DeltaSeconds;
				Data.CurrentDuration = Math::Clamp(Data.CurrentDuration, 0.0, MoveDuration + Data.AddedTime);
				float Alpha = Data.CurrentDuration / (MoveDuration + Data.AddedTime);
				AccelMoveAlpha.AccelerateTo(Alpha, 0.5, DeltaSeconds);
				Data.TargetLoc = Math::Lerp(Data.StartPosition, Data.EndPosition, MoveCurve.GetFloatValue(AccelMoveAlpha.Value));
				Data.TargetRot = Math::LerpShortestPath(Data.StartQuat.Rotator(), Data.EndQuat.Rotator(), RotateCurve.GetFloatValue(AccelMoveAlpha.Value));
				
				if (!Data.bCanWalkOn)
				{
					DeathVolume.DisableDeathVolume(this);
					auto Mesh = UStaticMeshComponent::Get(Data.Platform);
					Mesh.AddTag(ComponentTags::Walkable);			
					Mesh.AddTag(ComponentTags::InheritVerticalUpMovementIfGround);			
					Mesh.AddTag(ComponentTags::InheritVerticalDownMovementIfGround);			
					Mesh.AddTag(ComponentTags::InheritHorizontalMovementIfGround);			
					Data.bCanWalkOn = true;
				}
				
				if (Data.bIsMoving)
				{
					USummitMagicalPlatformManagerEventHandler::Trigger_MoveProgression(
						this, 
						FSummitMagicalPlatformProgressionParams(Data.Platform, MoveCurve.GetFloatValue(AccelMoveAlpha.Value), Data.TrailComp, Data.Platform.GetComponentByClass(UStaticMeshComponent)));
				}
			}
			bCanStartMovingBack = true;
		}
		else
		{
			for (FSummitMagicMoveablePlatforms& Data : PlatformData)
			{
				if (AccelMoveAlpha.Value < 0.5 && Data.bOverlayMaterialActive)
				{
					USummitMagicalPlatformManagerEventHandler::Trigger_StopOverlay(this);
					Data.bOverlayMaterialActive = false;
				}

				if (AccelMoveAlpha.Value < 0.05 && Data.bIsMoving)
				{
					Data.bIsMoving = false;
					DeathVolume.EnableDeathVolume(this);
					USummitMagicalPlatformManagerEventHandler::Trigger_StopMoving(this, FSummitMagicalPlatformStopMoveParams(Data.Platform, Data.TrailComp, Data.Platform.GetComponentByClass(UStaticMeshComponent)));
				}

				Data.CurrentDuration -= DeltaSeconds;
				Data.CurrentDuration = Math::Clamp(Data.CurrentDuration, 0.0, MoveDuration + Data.AddedTime);
				float Alpha = Data.CurrentDuration / (MoveDuration + Data.AddedTime);
				AccelMoveAlpha.AccelerateTo(Alpha, 0.5, DeltaSeconds);
				Data.TargetLoc = Math::Lerp(Data.StartPosition, Data.EndPosition, MoveCurve.GetFloatValue(AccelMoveAlpha.Value));
				Data.ZCurrentOffset = ZOffsetCurve.GetFloatValue(AccelMoveAlpha.Value) * ZOffset;
				Data.TargetLoc += FVector::UpVector * Data.ZCurrentOffset;
				Data.TargetRot = Math::LerpShortestPath(Data.StartQuat.Rotator(), Data.EndQuat.Rotator(), RotateCurve.GetFloatValue(AccelMoveAlpha.Value));
				
				if (Data.bCanWalkOn)
				{
					auto Mesh = UStaticMeshComponent::Get(Data.Platform);
					Mesh.RemoveTag(ComponentTags::Walkable);
					Mesh.RemoveTag(ComponentTags::InheritVerticalUpMovementIfGround);			
					Mesh.RemoveTag(ComponentTags::InheritVerticalDownMovementIfGround);			
					Mesh.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);	
					Data.bCanWalkOn = false;
				}

				if (Data.bIsMoving)
				{
					USummitMagicalPlatformManagerEventHandler::Trigger_MoveProgression(
						this, 
						FSummitMagicalPlatformProgressionParams(Data.Platform, MoveCurve.GetFloatValue(AccelMoveAlpha.Value), Data.TrailComp, Data.Platform.GetComponentByClass(UStaticMeshComponent)));
				}

				if (bCanStartMovingBack)
				{
					bCanStartMovingBack = false;
					USummitMagicalPlatformManagerEventHandler::Trigger_StartMoveDown(this);
					Print("YO", 10);
				}
			}			
		}

		for (FSummitMagicMoveablePlatforms& Data : PlatformData)
		{
			Data.Platform.ActorLocation = Data.AccelLoc.AccelerateTo(Data.TargetLoc, 0.75, DeltaSeconds);
			Data.Platform.ActorRotation = Data.AccelRot.AccelerateTo(Data.TargetRot, 0.75, DeltaSeconds);
		}
	}

	UFUNCTION()
	private void OnAcidActorActivated()
	{
		bActive = true;

		for (FSummitMagicMoveablePlatforms& Data : PlatformData)
		{
			auto Mesh = UStaticMeshComponent::Get(Data.Platform);
			// Mesh.RemoveComponentCollisionBlocker(this);
		}
	}

	UFUNCTION()
	private void OnAcidActorDeactivated()
	{
		bActive = false;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		// for (AActor Platform : Platforms)
		for (FSummitMagicMoveablePlatforms Data : PlatformData)
		{
			if (Data.Platform != nullptr)
				Debug::DrawDebugLine(ActorLocation, Data.Platform.ActorLocation, FLinearColor::Blue, 15.0);
			if (Data.OriginalPlatform != nullptr)
				Debug::DrawDebugLine(ActorLocation, Data.OriginalPlatform.ActorLocation, FLinearColor::Yellow, 15.0);
		}
		Debug::DrawDebugLine(ActorLocation, AcidActivator.ActorLocation, FLinearColor::Green, 15.0);
	}
#endif
};