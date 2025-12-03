//Adds a movement impulse to player while identifying it as a launch for animation purposes
UFUNCTION(Category = "Player")
mixin void AddPlayerLaunchMovementImpulse(AHazePlayerCharacter Player, FVector Impulse, bool bRotatePlayer = false, FName NameOfImpulse = NAME_None)
{
	Player.AddMovementImpulse(Impulse, NameOfImpulse);

	if(bRotatePlayer)
	{
		Player.SetMovementFacingDirection(Impulse.ConstrainToPlane(Player.MovementWorldUp).ToOrientationQuat());
	}

	UPlayerAirMotionComponent AirMotionComp = UPlayerAirMotionComponent::Get(Player);

	if(AirMotionComp == nullptr)
		return;
	
	AirMotionComp.AnimData.bPlayerLaunchDetected = true;
	AirMotionComp.AnimData.LaunchDetectedFrameCount = Time::GetFrameNumber();

	AirMotionComp.AnimData.InitialLaunchDirection = Impulse.GetSafeNormal();
	AirMotionComp.AnimData.InitialLaunchImpulse = Impulse;
}

//Adds a movement impulse required to reach stated height while also identifying velocity gain as a Launch for animation purposes
UFUNCTION(Category = "Player")
mixin void AddPlayerLaunchImpulseToReachHeight(AHazePlayerCharacter Player, float HeightToReach, bool bApplyImpulseToCounterVerticalSpeed = true, FName NameOfImpulse = NAME_None)
{
	if (Player == nullptr)
		return;

	if(!Player.HasActorBegunPlay())
		return;

	auto MoveComp = UHazeMovementComponent::Get(Player);
	if(MoveComp == nullptr)
	{
		devError(f"The Player {Player} needs a movement component to handle 'AddMovementImpulse' function calls");
		return;
	}

	devCheck(HeightToReach > 0.0, f"AddMovementImpulseToReachHeight was called on {Player} with HeightToReach being 0 or negative");

	// Based on calculate maximum height formula: h=v²/(2g), rearranged to solve for upwards speed based on max height and gravity: v=sqrt(h*2g)
	float Impulse = Math::Sqrt(2.0 * MoveComp.GravityForce * HeightToReach);
	if(bApplyImpulseToCounterVerticalSpeed)
		Impulse -= MoveComp.VerticalSpeed;

	MoveComp.AddPendingImpulse(MoveComp.WorldUp * Impulse, NameOfImpulse);

	UPlayerAirMotionComponent AirMotionComp = UPlayerAirMotionComponent::Get(Player);

	if(AirMotionComp == nullptr)
		return;

	AirMotionComp.AnimData.bPlayerLaunchDetected = true;
	AirMotionComp.AnimData.LaunchDetectedFrameCount = Time::GetFrameNumber();

	AirMotionComp.AnimData.InitialLaunchDirection = MoveComp.WorldUp;
	AirMotionComp.AnimData.InitialLaunchImpulse = MoveComp.WorldUp * Impulse;
}

//Will set animdata and flag player for launch animations
UFUNCTION(Category = "Player")
mixin void FlagForLaunchAnimations(AHazePlayerCharacter Player, FVector LaunchVelocity)
{
	if(Player == nullptr)
		return;

	UPlayerAirMotionComponent AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	
	if(AirMotionComp == nullptr)
		return;

	AirMotionComp.FlagForLaunchAnimations(LaunchVelocity);
}