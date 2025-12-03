class UTeenDragonTailBombPickupComponent : UInteractionComponent
{
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ActionShape = FHazeShapeSettings::MakeSphere(500);
	default FocusShape = FHazeShapeSettings::MakeSphere(1500);
	default MovementSettings = FMoveToParams::NoMovement();
}
