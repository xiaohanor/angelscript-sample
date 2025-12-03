struct FDentistBossCupCapturePlayerActivationParams
{
	bool bIsLeftGrabber;
	float CaptureDuration;
	EDentistBossTool CupType;
}

class UDentistBossCupCapturePlayerCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolCup Cup;

	UDentistBossTargetComponent TargetComp;
	
	FDentistBossCupCapturePlayerActivationParams Params;

	UDentistBossSettings Settings;

	AHazePlayerCharacter TargetPlayer;
	UPlayerMovementComponent TargetPlayerMoveComp;

	float StartLoweringZ;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossCupCapturePlayerActivationParams InParams)
	{
		Params = InParams;
		TargetPlayer = TargetComp.Target.Get();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TargetPlayer.IsPlayerDead())
			return false;

		if(!TargetComp.IsOnCake[TargetPlayer])
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.CaptureDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cup = Cast<ADentistBossToolCup>(Dentist.Tools[Params.CupType]);
		TargetPlayerMoveComp = UPlayerMovementComponent::Get(TargetPlayer);
		TargetPlayerMoveComp.AddMovementIgnoresActor(this, Cup);
		Cup.MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

		FTransform HandTransform = Dentist.GetIKTransform(EDentistBossArm::LeftTop);
		StartLoweringZ = HandTransform.Location.Z;
		Dentist.bCupCaptureTelegraphDone = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetPlayerMoveComp.RemoveMovementIgnoresActor(this);
		Cup.MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);

		Cup.RestrainedPlayer.Set(TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Params.CaptureDuration == 0)
			return;

		float MoveAlpha = ActiveDuration / Params.CaptureDuration;
		float LerpedZ;

		MoveAlpha = Math::EaseIn(0.0, 1.0, MoveAlpha, 2.0);
		MoveAlpha = Math::Clamp(MoveAlpha, 0.0, 1.0);
		float TargetZ = Dentist.Cake.ActorLocation.Z + DentistBossMeasurements::CupHeight;
		LerpedZ = Math::Lerp(StartLoweringZ, TargetZ, MoveAlpha);

		FVector NewLocation = TargetPlayer.ActorLocation;
		NewLocation.Z = LerpedZ;

		FRotator TargetRotation = FRotator::MakeFromXZ(-FVector::UpVector, Dentist.ActorRightVector);

		if(NewLocation.Z < TargetPlayer.ActorLocation.Z + DentistBossMeasurements::CupHeight)
			Cup.RestrainedPlayer.Set(TargetPlayer);

		Dentist.SetIKTransform(EDentistBossArm::LeftTop, NewLocation, TargetRotation);
	}
};