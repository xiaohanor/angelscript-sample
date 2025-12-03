class USkylineHighwayPlayerFollowComponent : UActorComponent
{
	UFUNCTION()
	void StartFollow()
	{
		UPlayerMovementComponent::Get(Game::Mio).FollowComponentMovement(Owner.RootComponent, this);
		UPlayerMovementComponent::Get(Game::Zoe).FollowComponentMovement(Owner.RootComponent, this);
	}

	UFUNCTION()
	void StopFollow()
	{
		UPlayerMovementComponent::Get(Game::Mio).UnFollowComponentMovement(this);
		UPlayerMovementComponent::Get(Game::Zoe).UnFollowComponentMovement(this);
	}
}