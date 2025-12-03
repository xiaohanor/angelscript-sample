class UMeltdownWorldSpinnerPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	UHazeCrumbSyncedFloatComponent AngleSyncComp;
	AMeltdownWorldSpinManager Manager;

	float SpinAngle = 0.0;
	float SpinVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);

		AngleSyncComp = UHazeCrumbSyncedFloatComponent::Create(Player, n"WorldSpinRotationAngle");
		AngleSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		AngleSyncComp.SleepAfterIdleTime = MAX_flt;

		Manager = TListedActors<AMeltdownWorldSpinManager>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bManagerActive)
			return false;
		if (Player != Manager.SpinPlayer)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Manager.bManagerActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.OtherPlayer.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector2D StickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

			SpinVelocity = Math::FInterpConstantTo(
				SpinVelocity, MeltdownWorldSpin::MaxSpinVelocity * StickInput.X,
				DeltaTime, MeltdownWorldSpin::SpinAcceleration,
			);

			float PrevSpinAngle = SpinAngle;
			SpinAngle += SpinVelocity * DeltaTime;
			SpinAngle = Math::Clamp(SpinAngle, -MeltdownWorldSpin::MaxSpinAngle, MeltdownWorldSpin::MaxSpinAngle);
			SpinVelocity = (SpinAngle - PrevSpinAngle) / DeltaTime;

			Manager.UpdateWorldSpinRotation(FQuat(FVector::ForwardVector, Math::DegreesToRadians(SpinAngle)), SpinAngle);
			AngleSyncComp.Value = SpinAngle;

			if(SpinVelocity > 1.0)
			{
				float FFFrequency = 10;
				float FFIntensity = 0.1;
				FHazeFrameForceFeedback FF;
				FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF);
			}
			 if(SpinVelocity < -1.0)
			{
				float FFFrequency = 20;
				float FFIntensity = 0.1;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF);
			}

		}
		else
		{
			SpinAngle = AngleSyncComp.Value;
		}

		float FinalSpinAngle = SpinAngle;
		if (Manager.bHasForcedAngle)
		{
			float Alpha = Math::Saturate(Time::GetGameTimeSince(Manager.ForcedAngleBlendStart) / Manager.ForcedAngleBlendDuration);
			FinalSpinAngle = Math::Lerp(SpinAngle, Manager.ForcedAngle, Math::EaseInOut(0, 1, Alpha, 2));
		}

		Manager.UpdateWorldSpinRotation(FQuat(FVector::ForwardVector, Math::DegreesToRadians(FinalSpinAngle)), FinalSpinAngle);
		Player.OtherPlayer.OverrideGravityDirection(-Manager.WorldSpinRotation.UpVector, this);
	}
};