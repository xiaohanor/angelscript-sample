// This capability will start orienting robot to initial player camera forward while player launches
class UTazerBotPlayerEnterCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	default CapabilityTags.Add(PrisonTags::Prison);
	default TickGroupOrder = 4;

	ATazerBot TazerBot;

	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FVector PlayerCameraForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.bPlayerHackLaunching)
			return false;

		if (TazerBot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate when player reaches hackable
		if (TazerBot.IsHacked())
			return true;

		if (TazerBot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerCameraForward = TazerBot.HackingPlayer.ViewRotation.ForwardVector.ConstrainToPlane(MovementComponent.WorldUp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TazerBot.bPlayerHackLaunching = false;

		// Cache base rotation
		FRotator BaseRotation = TazerBot.MeshComponent.GetBoneRotationByName(n"Base", EBoneSpaces::WorldSpace);

		// Set rotation to head (otherwise it will reset) when TazerBotMovementCapability kicks in
		TazerBot.TeleportActor(TazerBot.ActorLocation, TazerBot.MeshComponent.GetBoneRotationByName(n"Head",EBoneSpaces::WorldSpace), this);

		// Mesh ignores actor rotation
		TazerBot.MeshRoot.SetRelativeRotation(TazerBot.ActorQuat.Inverse());

		// Restore base rotation
		TazerBot.MeshComponent.SetBoneRotationByName(n"Base", BaseRotation, EBoneSpaces::WorldSpace);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat TurretRotation = TazerBot.MeshComponent.GetBoneRotationByName(n"Head",EBoneSpaces::WorldSpace).Quaternion();
		FVector ForwardVector = TazerBot.HackingPlayer.ViewRotation.ForwardVector.ConstrainToPlane(MovementComponent.WorldUp);

		FQuat TargetRotation = FQuat::MakeFromX(ForwardVector);
		float InterpSpeed = TazerBot.PlayerHackLaunchParams.LaunchSpeed * DeltaTime * 0.1;

		float AngularDistance = (ForwardVector.AngularDistance(TurretRotation.ForwardVector));
		InterpSpeed = AngularDistance / (TazerBot.PlayerHackLaunchParams.LaunchDuration * 0.5);

		TurretRotation = Math::QInterpConstantTo(TurretRotation, TargetRotation, DeltaTime, InterpSpeed);
		TazerBot.MeshComponent.SetBoneRotationByName(n"Head", TurretRotation.Rotator(), EBoneSpaces::WorldSpace);
	}
}