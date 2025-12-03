class ASpaceWalkHookAdjustVolume : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.39, 0.88, 0.45));

	UPROPERTY(DefaultComponent)
	UArrowComponent Direction;

	UPROPERTY(EditAnywhere)
	float Acceleration = 500;

    void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
    {
        Super::TriggerOnPlayerEnter(Player);

		auto SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		SpaceComp.AdjustAcceleration.Apply(Direction.ForwardVector * Acceleration, this);
    }

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);

		auto SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		SpaceComp.AdjustAcceleration.Clear(this);
	}
};