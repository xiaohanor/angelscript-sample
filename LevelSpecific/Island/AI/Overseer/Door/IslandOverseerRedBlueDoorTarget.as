UCLASS(Abstract)
class AIslandOverseerRedBlueDoorTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer UsableByPlayer;

	UPROPERTY(EditAnywhere)
	FVector HiddenOffset;

	UPROPERTY(EditAnywhere)
	AActor Hatch;

	UPROPERTY(EditAnywhere)
	FVector HatchClosedOffset;

	AAIIslandOverseer Overseer;
	FHazeAcceleratedFloat AccSpeed;
	float ImpactTime;
	float ImpactDuration = 0.5;
	float BaseSpeed = 150;
	float CurrentSpeed;
	bool bDisabled;
	bool bCutting;
	float EnableTime;
	float DisableTime;
	float EnableDisableDuration = 3;
	FHazeAcceleratedVector AccEmissive;

	FLinearColor DefaultColor;
	UMaterialInstanceDynamic DynamicMaterial;

	FVector OriginalLocation;
	FVector HiddenLocation;
	FHazeAcceleratedVector AccUnhide;

	FVector HatchOpenLocation;
	FVector HatchClosedLocation;
	FHazeAcceleratedVector AccHatchLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		Overseer = TListedActors<AAIIslandOverseer>().GetSingle();
		Overseer.DamageResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpactOverseer");
		Overseer.DoorComp.OnHeadCutStart.AddUFunction(this, n"HeadCutStart");
		Overseer.DoorComp.OnHeadCutStop.AddUFunction(this, n"HeadCutStop");

		OriginalLocation = ActorLocation;
		HiddenLocation = ActorLocation + HiddenOffset;
		ActorLocation = HiddenLocation;
		AccUnhide.SnapTo(HiddenLocation);

		Overseer.PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");

		DynamicMaterial = Mesh.CreateDynamicMaterialInstance(1);
		DefaultColor = DynamicMaterial.GetVectorParameterValue(n"Global_EmissiveTint");
		
		CurrentSpeed = BaseSpeed;

		HatchOpenLocation = Hatch.ActorLocation;
		HatchClosedLocation = Hatch.ActorLocation + HatchClosedOffset;
		Hatch.ActorLocation = HatchClosedLocation;
		AccHatchLocation.SnapTo(HatchClosedLocation);

		bDisabled = true;
	}

	UFUNCTION()
	private void PhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		if(NewPhase != EIslandOverseerPhase::DoorCutHead)
			return;

		if(OldPhase == EIslandOverseerPhase::Door)
			Timer::SetTimer(this, n"Delayed", 3);
		else
			Timer::SetTimer(this, n"Delayed", 1);
	}

	UFUNCTION()
	private void Delayed()
	{
		EnableTarget();		
	}

	UFUNCTION()
	private void HeadCutStart()
	{
		bCutting = true;
		CurrentSpeed = BaseSpeed * 2;
	}

	UFUNCTION()
	private void HeadCutStop()
	{
		bCutting = false;
	}

	void EnableTarget()
	{
		if(!bDisabled)
			return;
		TArray<UStaticMeshComponent> Meshes;
		MeshOffsetComponent.GetChildrenComponentsByClass(UStaticMeshComponent, false, Meshes);
		DynamicMaterial.SetVectorParameterValue(n"Global_EmissiveTint", DefaultColor);
		bDisabled = false;
		UIslandOverseerRedBlueDoorTargetEventHandler::Trigger_OnOpenStart(this);
		EnableTime = Time::GameTimeSeconds + EnableDisableDuration;
	}

	void DisableTarget()
	{
		if(bDisabled)
			return;
		TArray<UStaticMeshComponent> Meshes;
		MeshOffsetComponent.GetChildrenComponentsByClass(UStaticMeshComponent, false, Meshes);
		DynamicMaterial.SetVectorParameterValue(n"Global_EmissiveTint", FLinearColor::Gray);
		bDisabled = true;
		UIslandOverseerRedBlueDoorTargetEventHandler::Trigger_OnCloseStart(this);
		DisableTime = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void OnImpactOverseer(FIslandRedBlueImpactResponseParams Data)
	{		
		if(Overseer.PhaseComp.Phase != EIslandOverseerPhase::DoorCutHead)
			return;
		if(bCutting)
			return;

		if(!Overseer.DoorComp.bDoorClosing && Time::GetGameTimeSince(ImpactTime) > 0.5)
		{
			ImpactTime = Time::GameTimeSeconds;
			ImpactDuration = 0.1;
			CurrentSpeed *= -1;
		}
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(bDisabled)
			return;
		if(UsableByPlayer == EHazeSelectPlayer::Mio && Data.Player != Game::Mio)
			return;
		if(UsableByPlayer == EHazeSelectPlayer::Zoe && Data.Player != Game::Zoe)
			return;

		if(AccEmissive.Value.Size() < 5)
			AccEmissive.SnapTo(FVector(DefaultColor.R, DefaultColor.G, DefaultColor.B) * 40);
		
		Overseer.DoorComp.OnDoorImpulse.Broadcast(Data.Player);

		if(ImpactTime == 0)
			UIslandOverseerRedBlueDoorTargetEventHandler::Trigger_OnTargetActivated(this);
		
		if(!Overseer.DoorComp.bDoorClosing && Time::GetGameTimeSince(ImpactTime) > 0.5)
		{
			ImpactTime = Time::GameTimeSeconds;
			ImpactDuration = 0.1;
			CurrentSpeed *= -1;
		}
		else if(Overseer.DoorComp.bDoorClosing)
		{
			ImpactTime = Time::GameTimeSeconds;
			ImpactDuration = 0.5;
			CurrentSpeed = BaseSpeed;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCutting || (ImpactTime != 0 && Time::GetGameTimeSince(ImpactTime) < ImpactDuration))
			AccSpeed.AccelerateTo(CurrentSpeed, 0.5, DeltaSeconds);
		else
		{
			AccSpeed.SpringTo(0, 350, 0.15, DeltaSeconds);

			if(ImpactTime > 0 && AccSpeed.Value < 0.1)
			{
				UIslandOverseerRedBlueDoorTargetEventHandler::Trigger_OnTargetDeactivated(this);
				ImpactTime = 0;
			}
		}

		MeshOffsetComponent.AddLocalRotation(FRotator(AccSpeed.Value, 0, 0) * DeltaSeconds);

		AccEmissive.AccelerateTo(FVector(DefaultColor.R, DefaultColor.G, DefaultColor.B), 0.075, DeltaSeconds);
		DynamicMaterial.SetVectorParameterValue(n"Global_EmissiveTint", FLinearColor(AccEmissive.Value.X, AccEmissive.Value.Y, AccEmissive.Value.Z, DefaultColor.A));

		if(bDisabled)
		{
			AccUnhide.AccelerateTo(HiddenLocation, EnableDisableDuration, DeltaSeconds);
			ActorLocation = AccUnhide.Value;

			AccHatchLocation.AccelerateTo(HatchClosedLocation, EnableDisableDuration, DeltaSeconds);
			Hatch.ActorLocation = AccHatchLocation.Value;

			if(DisableTime > 0 && AccUnhide.Value.PointsAreNear(HiddenLocation, 25))
			{
				DisableTime = 0;
				UIslandOverseerRedBlueDoorTargetEventHandler::Trigger_OnCloseStop(this);
			}
		}
		else
		{
			AccUnhide.AccelerateTo(OriginalLocation, EnableDisableDuration, DeltaSeconds);
			ActorLocation = AccUnhide.Value;

			AccHatchLocation.AccelerateTo(HatchOpenLocation, EnableDisableDuration, DeltaSeconds);
			Hatch.ActorLocation = AccHatchLocation.Value;

			if(EnableTime > 0 && AccUnhide.Value.PointsAreNear(OriginalLocation, 25))
			{
				EnableTime = 0;
				UIslandOverseerRedBlueDoorTargetEventHandler::Trigger_OnOpenStop(this);
			}
		}		
	}
}