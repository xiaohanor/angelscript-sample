class UNightQueenArmouredFacePlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenArmouredFacePlayerCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenArmouredArm ArmouredArm;
	AHazePlayerCharacter TargetPlayer;

	float DecisionSpeed = 1.0;
	float DecisionTime;
	float RotationSpeed = 50.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ArmouredArm = Cast<ANightQueenArmouredArm>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArmouredArm.bIsPose)
			return false;

		if (ArmouredArm.TargetPlayers.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ArmouredArm.bIsPose)
			return true;

		if (ArmouredArm.TargetPlayers.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ArmouredArm.SetReadyPose();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ArmouredArm.SetDefaultPose();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > DecisionTime)
		{
			DecisionTime = Time::GameTimeSeconds + DecisionSpeed;
			TargetPlayer = ArmouredArm.GetClosestTargetPlayer();
		}

		if (ArmouredArm.bAttacking)
			return;

		FVector Dir = (TargetPlayer.ActorLocation - ArmouredArm.ActorLocation);
		Dir = Dir.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		ArmouredArm.ActorRotation = Math::RInterpConstantTo(ArmouredArm.ActorRotation, Dir.Rotation(), DeltaTime, RotationSpeed);
	}
}