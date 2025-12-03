 UFUNCTION(Category = "Movement Camera")
 mixin EPlayerMovementPerspectiveMode GetCurrentGameplayPerspectiveMode(AHazePlayerCharacter Player)
 {
	auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	return PerspectiveModeComp.GetPerspectiveMode();
 }

 UFUNCTION(Category = "Movement Camera")
 mixin bool IsMovementCameraBehaviorEnabled(AHazePlayerCharacter Player)
 {
	auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	return PerspectiveModeComp.IsCameraBehaviorEnabled();
 }

/**
 * This function will set both the Movement Perspective Mode as well as TargetingMode
 */
 UFUNCTION(Category = "Gameplay Mode", Meta = (Keywords = "Perspective Targeting"))
 mixin void ApplyGameplayPerspectiveMode(AHazePlayerCharacter Player, EPlayerMovementPerspectiveMode Mode, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
 {
	auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	PerspectiveModeComp.ApplyPerspectiveMode(Mode, Instigator);

	EPlayerTargetingMode NewMode;
	switch (Mode)
	{
		case EPlayerMovementPerspectiveMode::ThirdPerson:
			NewMode = EPlayerTargetingMode::ThirdPerson;
			break;

		case EPlayerMovementPerspectiveMode::SideScroller:
			NewMode = EPlayerTargetingMode::SideScroller;
			break;

		case EPlayerMovementPerspectiveMode::TopDown:
			NewMode = EPlayerTargetingMode::TopDown;
			break;
		
		case EPlayerMovementPerspectiveMode::MovingTowardsCamera:
			NewMode = EPlayerTargetingMode::MovingTowardsCamera;
			break;

		default:
			NewMode = EPlayerTargetingMode::ThirdPerson;
			check(false);
			break;
	}

	auto TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	TargetablesComp.TargetingMode.Apply(NewMode, Instigator, Priority);
 }

 UFUNCTION(Category = "Gameplay Mode", Meta = (Keywords = "Perspective Targeting"))
 mixin void ClearGameplayPerspectiveMode(AHazePlayerCharacter Player, FInstigator Instigator)
 {
	auto TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	TargetablesComp.TargetingMode.Clear(Instigator);

	auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	PerspectiveModeComp.ClearPerspectiveMode(Instigator);
 }