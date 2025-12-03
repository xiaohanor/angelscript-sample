struct FDentistBossToolCupFlattenWithPlayerActivationParams
{
	AHazePlayerCharacter FlattenedPlayer;
}

class UDentistBossToolCupFlattenWithPlayerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolCup Cup;
	ADentistBossCupManager CupManager;
	ADentistBoss Dentist;
	ADentistBossToolDrill Drill;

	UDentistToothPlayerComponent ToothComp;
	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;

	AHazePlayerCharacter FlattenedPlayer;
	
	FHazeAcceleratedVector AccScale;
	FVector AppliedRelativeOffset;

	bool bButtonMashFinished = false;
	bool bOffsetReset = false;

	const float PlayerOffsetResetDuration = 0.5;

	float TimeLastCompletedButtonMash = -MAX_flt;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cup = Cast<ADentistBossToolCup>(Owner);

		Dentist = TListedActors<ADentistBoss>().GetSingle();
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
		CupManager = Dentist.CupManager;

		Drill = TListedActors<ADentistBossToolDrill>().Single;

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolCupFlattenWithPlayerActivationParams& Params) const
	{
		if(!Cup.bActive)
			return false;

		if(!Cup.FlattenedPlayer.IsSet())
			return false;

		Params.FlattenedPlayer = Cup.FlattenedPlayer.Value;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(FlattenedPlayer.IsPlayerDead())
			return true;

		if(bOffsetReset)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolCupFlattenWithPlayerActivationParams Params)
	{
		FlattenedPlayer = Params.FlattenedPlayer;
		FlattenedPlayer.BlockCapabilities(CapabilityTags::Movement, this);

		FlattenedPlayer.PlayCameraShake(Settings.CupFlattenPlayerCameraShake, this);
		FlattenedPlayer.PlayForceFeedback(Settings.CupFlattenPlayerForceFeedback, false, true, this);
		FlattenedPlayer.BlockCapabilities(n"DamageCameraShake", this);
		FlattenedPlayer.BlockCapabilities(n"Death", this);
		FlattenedPlayer.DamagePlayerHealth(Settings.CupFlattenPlayerDamage);
		FlattenedPlayer.UnblockCapabilities(n"DamageCameraShake", this);
		FlattenedPlayer.UnblockCapabilities(n"Death", this);

		FlattenedPlayer.SetActorRotation(FRotator::MakeFromXZ(Dentist.Cake.ActorRightVector, FVector::UpVector));

		FlattenedPlayer.Mesh.ResetAllAnimation(true);
		FlattenedPlayer.Mesh.bPauseAnims = true;

		ToothComp = UDentistToothPlayerComponent::Get(FlattenedPlayer);
		FQuat MeshRotation = FQuat::MakeFromXZ(FVector::UpVector, -Dentist.Cake.ActorRightVector);
		ToothComp.SetMeshWorldRotation(MeshRotation, this);
		FlattenedPlayer.MeshOffsetComponent.SetRelativeScale3D(Settings.CupSmashedPlayerScale);
		AccScale.SnapTo(Settings.CupSmashedPlayerScale);
		FVector RelativeOffset = FVector::ForwardVector * (FlattenedPlayer.CapsuleComponent.CapsuleHalfHeight * Settings.CupSmashedPlayerScale.X);
		FlattenedPlayer.MeshOffsetComponent.SnapToRelativeLocation(this
			, FlattenedPlayer.RootComponent, RelativeOffset, EInstigatePriority::High);
		AppliedRelativeOffset = RelativeOffset;

		FlattenedPlayer.StartButtonMash(Settings.CupPlayerFlattenedButtonMashSettings, this, FOnButtonMashCompleted(this, n"OnButtonMashCompleted"));
		bButtonMashFinished = false;
		bOffsetReset = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Cup.Deactivate();
		Cup.FlattenedPlayer.Reset();

		FlattenedPlayer.MeshOffsetComponent.SetRelativeScale3D(FVector::OneVector);
		FlattenedPlayer.Mesh.bPauseAnims = false;
		FlattenedPlayer.MeshOffsetComponent.ClearOffset(this);
		FlattenedPlayer.StopButtonMash(this);
		
		if(!bButtonMashFinished)
			PostButtonMashCompleted();
	}

	UFUNCTION()
	private void OnButtonMashCompleted()
	{
		PostButtonMashCompleted();
	}

	void PostButtonMashCompleted()
	{
		FlattenedPlayer.MeshOffsetComponent.SetRelativeScale3D(FVector::OneVector);
		FlattenedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);

		FlattenedPlayer.SetActorVelocity(FVector::UpVector * Settings.CupSmashedPlayerButtonMashCompletedImpulseScale);
		FlattenedPlayer.Mesh.bPauseAnims = false;

		TimeLastCompletedButtonMash = Time::GameTimeSeconds;
		bButtonMashFinished = true;

		FlattenedPlayer.PlayForceFeedback(ForceFeedback::Default_Medium, this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bButtonMashFinished)
		{
			float ButtonMashProgress = FlattenedPlayer.GetButtonMashProgress(this);
			float CurveAlpha = Settings.CupSmashedPlayerScaleCurve.GetFloatValue(ButtonMashProgress);
			FVector StartScale = Settings.CupSmashedPlayerScale;
			FVector EndScale = FVector::OneVector;

			FVector NewScale = Math::Lerp(StartScale, EndScale, CurveAlpha);
			AccScale.AccelerateTo(NewScale, 0.1, DeltaTime);

			FlattenedPlayer.MeshOffsetComponent.SetRelativeScale3D(AccScale.Value);
			
			if(FlattenedPlayer.Mesh.CanRequestLocomotion())
				FlattenedPlayer.RequestLocomotion(Dentist::Feature, this);

			if(Drill.TargetedPlayer == FlattenedPlayer
			&& TargetComp.bIsDrilling)
			{
				FlattenedPlayer.StopButtonMash(this);
				PostButtonMashCompleted();
			}
		}
		else
		{
			float TimeSinceCompletedButtonMash = Time::GetGameTimeSince(TimeLastCompletedButtonMash);
			float ResetAlpha = TimeSinceCompletedButtonMash / PlayerOffsetResetDuration;
			ResetAlpha = Math::Saturate(ResetAlpha);
			if(ResetAlpha == 1.0)
				bOffsetReset = true;
			else
			{
				FVector TargetRelativeLocation = FlattenedPlayer.CapsuleComponent.RelativeLocation;
				FVector RelativeLocation = Math::Lerp(AppliedRelativeOffset, TargetRelativeLocation, ResetAlpha);
				FlattenedPlayer.MeshOffsetComponent.SnapToRelativeLocation(this
					, FlattenedPlayer.RootComponent, RelativeLocation, EInstigatePriority::High);

				TEMPORAL_LOG(FlattenedPlayer, "Flatten Offset Reset")
					.Value("Reset Alpha", ResetAlpha)
					.Value("Applied Initial offset", AppliedRelativeOffset)
					.Value("Target Relative Offset", TargetRelativeLocation)
					.Value("Relative Location", RelativeLocation)
				;
			}
		}
	}
}