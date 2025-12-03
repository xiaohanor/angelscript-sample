class USummitSmashapultComponent : UActorComponent
{
	UPROPERTY()
	FVector TargetLocation;	

	// When there are any peacekeepers we don't start any attacks, but ongoing attacks are allowed to complete
	TArray<FInstigator> PeaceKeepers;

	// Only gets set in the seesaw launch sequence to activate the launch capability
	TOptional<FVector> LaunchTarget;
}
