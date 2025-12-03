class UTundraShellyShellMoveBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UTundraShellySettings ShellySettings;
	UBasicAIHealthComponent HealthComp;
	UTundraShellyShellComponent ShellComp;
	UBasicAICharacterMovementComponent MoveComp;
	AHazeCharacter Character;
	bool bHit;
	FVector Direction;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShellySettings = UTundraShellySettings::GetSettings(Cast<AHazeActor>(Owner));
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ShellComp = UTundraShellyShellComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Character = Cast<AHazeCharacter>(Owner);

		UTundraPlayerSnowMonkeyGroundSlamResponseComponent SlamComp = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::GetOrCreate(Owner);
		SlamComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		if(ShellComp.bShelled && !IsActive())
			bHit = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!ShellComp.bShelled)
			return false;
		if(!bHit)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!ShellComp.bShelled)
			return true;
		if(Speed <= 100)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHit = false;
		Direction = (Owner.ActorLocation - Game::Mio.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		Speed = 5000;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ShellComp.ExitShell();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Speed -= DeltaTime * 1000;
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + Direction * 50, Speed);
		ShouldChangeDirection();
	}

	void ShouldChangeDirection()
	{
		if(MoveComp.HasWallContact())
		{
			FVector Velocity = Owner.ActorVelocity.GetSafeNormal();
			FVector u = MoveComp.WallContact.Normal * Velocity.DotProduct(MoveComp.WallContact.Normal);
			FVector w = Velocity - u;
			Direction = w - u;
		}
	}
}

