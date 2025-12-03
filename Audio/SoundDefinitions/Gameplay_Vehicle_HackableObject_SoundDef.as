
UCLASS(Abstract)
class UGameplay_Vehicle_HackableObject_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnObjectStartMoving(){}

	UFUNCTION(BlueprintEvent)
	void OnObjectStopMoving(){}

	UFUNCTION(BlueprintEvent)
	void OnAbilityToggleActivated(){}

	UFUNCTION(BlueprintEvent)
	void OnAbilityToggleDeactivated(){}

	UFUNCTION(BlueprintEvent)
	void OnAbilityOneshot(){}

	UFUNCTION(BlueprintEvent)
	void OnObjectMoving(){}

	UFUNCTION(BlueprintEvent)
	void OnCameraStartMoving(){}

	UFUNCTION(BlueprintEvent)
	void OnCameraStopMoving(){}

	UFUNCTION(BlueprintEvent)
	void OnCameraMoving(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	URemoteHackingPlayerComponent PlayerHackingComp;

	private USwarmDroneHijackTargetableComponent HijackTargetableComp;
	private URemoteHackingResponseComponent RemoteHackingComp;

	UPROPERTY(EditAnywhere, Category = "Logic")
	float VoiceVolumeMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Category = "Logic")
	float MakeUpGainMultiplier = 1.0;

	UPROPERTY(Category = "Movement|Object")
	bool bCanMove = true;

	// If true movement speed will be in negative range when the object is moving opposite to its forward vector director
	UPROPERTY(Category = "Movement|Object")
	bool bTrackMovementDirection = false;

	UPROPERTY(Category = "Movement|Object")
	FName RotationRootCompName = NAME_None;

	// Range to normalize movement speed to
	UPROPERTY(Category = "Movement|Object")
	float MovementSpeedNormalizationRange = 500;

	UPROPERTY(Category = "Movement|Object", Meta = (EditCondition = bCanMove))
	float ObjectMovementAttack = 0.0;

	UPROPERTY(Category = "Movement|Object", Meta = (EditCondition = bCanMove))
	float ObjectMovementRelease = 0.0;

	UPROPERTY(Category = "Movement|Object", Meta = (EditCondition = bCanMove))
	UHazeAudioEvent ObjectStartMovingEvent;

	UPROPERTY(Category = "Movement|Object", Meta = (EditCondition = bCanMove))
	UHazeAudioEvent ObjectStopMovingEvent;

	// If true this object will play events for movement relative to camera
	UPROPERTY(Category = "Movement|Camera")
	bool bTrackCameraMovement = false;

	// Range to normalize movement speed to
	// Smaller value = react faster to movement
	// Larger value = react slower to movement
	UPROPERTY(Category = "Movement|Camera", Meta = (UIMin = 0.0, UIMax = 1.0, EditCondition = "bTrackCameraMovement"))
	float CameraSpeedNormalizationRange = 0.5;

	UPROPERTY(Category = "Movement|Camera", Meta = (EditCondition = bTrackCameraMovement))
	float CameraMovementAttack = 0.0;

	UPROPERTY(Category = "Movement|Camera", Meta = (EditCondition = bTrackCameraMovement))
	float CameraMovementRelease = 0.0;

	UPROPERTY(Category = "Movement|Camera", Meta = (EditCondition = bTrackCameraRelativeMovement))
	UHazeAudioEvent CameraStartMovingEvent;

	UPROPERTY(Category = "Movement|Camera", Meta = (EditCondition = bTrackCameraRelativeMovement))
	UHazeAudioEvent CameraStopMovingEvent;

	UPROPERTY(Category = "Ability")
	bool bHasToggleAbility = false;

	UPROPERTY(Category = "Ability")
	UHazeAudioEvent AbilityToggleActivatedEvent;

	UPROPERTY(Category = "Ability")
	UHazeAudioEvent AbilityToggleDeactivatedEvent;

	UPROPERTY(Category = "Ability")
	bool bHasOneShotAbility = false;

	UPROPERTY(Category = "Ability")
	UHazeAudioEvent AbilityOneShotEvent;

	UPROPERTY()
	UHazeAudioEvent HackingActivatedEvent;

	UPROPERTY()
	UHazeAudioEvent HackingDeactivatedEvent;

	private bool bIsHacked = false;
	private bool bIsRemoteHackable = false;

	private USceneComponent RotationRootComp;
	private FVector LastObjectLocation;
	private FRotator LastCameraRotation;

	private float ObjectMovementSpeed;
	private float ObjectMovingDirValue;

	private float CameraRotationDelta;

	private bool bObjectWasMoving = false;
	private bool bCameraWasMoving = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HijackTargetableComp = USwarmDroneHijackTargetableComponent::Get(HazeOwner);	

		if(HijackTargetableComp != nullptr)
		{
			bIsHacked = HijackTargetableComp.IsHijacked();
			HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"OnHijackStart");
			HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"OnHijackStop");
		}
		else
		{
			PlayerHackingComp = URemoteHackingPlayerComponent::Get(Game::GetMio());
			RemoteHackingComp = URemoteHackingResponseComponent::Get(HazeOwner);
			bIsRemoteHackable = true;
		}

		if(RotationRootCompName != NAME_None)
			RotationRootComp = USceneComponent::Get(HazeOwner, RotationRootCompName);
	}	

	UFUNCTION()
	void OnHijackStart(FSwarmDroneHijackParams HijackParams)
	{
		bIsHacked = true;
	}

	UFUNCTION()
	void OnHijackStop()
	{
		bIsHacked = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bIsRemoteHackable)
			return RemoteHackingComp.bHacked;
			
		return bIsHacked;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bIsRemoteHackable)
			return !RemoteHackingComp.bHacked;

		return !bIsHacked;
	}

	UFUNCTION(BlueprintPure)
	float GetMovementDirectionMultiplier()
	{
		if(!bTrackMovementDirection)
			return 1.0;

		const FVector Velo = HazeOwner.GetActorLocation() - LastObjectLocation;
		const float DirectionDot = Velo.GetSafeNormal().DotProduct(HazeOwner.GetActorForwardVector());
		
		return DirectionDot;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bCanMove)
			HandleObjectMovement(DeltaSeconds);

		if(bTrackCameraMovement)
			HandleCameraMovement(DeltaSeconds);
	}			

	private void HandleObjectMovement(float DeltaSeconds)
	{
		const FVector CurrentObjectLocation = HazeOwner.GetActorLocation();
		const FVector Velo = CurrentObjectLocation - LastObjectLocation;

		const float MovementSpeed = Velo.Size() / DeltaSeconds;
		ObjectMovementSpeed = Math::GetMappedRangeValueClamped(FVector2D(0, MovementSpeedNormalizationRange), FVector2D(0, 1), MovementSpeed);
		const bool bIsMoving = ObjectMovementSpeed > 0;

		if(bIsMoving)
		{
			if(bTrackMovementDirection && RotationRootComp != nullptr)
			{
				ObjectMovingDirValue = Velo.GetSafeNormal().DotProduct(RotationRootComp.GetForwardVector());
			}

			if(!bObjectWasMoving)
			{
				OnObjectStartMoving();
				bObjectWasMoving = true;
			}
			else
			{
				OnObjectMoving();
			}
		}		
		else if(bObjectWasMoving)
		{
			OnObjectStopMoving();
			bObjectWasMoving = false;
		}

		LastObjectLocation = CurrentObjectLocation;
	}

	private FRotator GetCameraViewRotation() const
	{
		if(bIsRemoteHackable)
			return RemoteHackingComp.HackingPlayer.GetViewRotation();

		return HijackTargetableComp.GetHijackPlayer().GetViewRotation();
	}

	private void HandleCameraMovement(float DeltaSeconds)
	{
		const FRotator CurrentCameraRotation = GetCameraViewRotation();
		CameraRotationDelta = CurrentCameraRotation.Quaternion().AngularDistance(LastCameraRotation.Quaternion()) / DeltaSeconds;
		CameraRotationDelta = Math::GetMappedRangeValueClamped(FVector2D(0, CameraSpeedNormalizationRange), FVector2D(0, 1), CameraRotationDelta);

		if(CameraRotationDelta >= 0.01)
		{
			if(!bCameraWasMoving)
			{
				OnCameraStartMoving();
				bCameraWasMoving = true;
			}
			else
			{
				OnCameraMoving();
			}
		}
		else if(bCameraWasMoving)
		{
			OnCameraStopMoving();
			bCameraWasMoving = false;
		}

		LastCameraRotation = CurrentCameraRotation;
	}	

	UFUNCTION(BlueprintPure)
	void GetObjectMovementSpeed(float&out Speed, float&out Direction)
	{
		Speed = ObjectMovementSpeed;
		Direction = ObjectMovingDirValue;
	}

	UFUNCTION(BlueprintPure)
	void GetCameraMovementSpeed(float&out Speed)
	{
		Speed = CameraRotationDelta;
	}
}