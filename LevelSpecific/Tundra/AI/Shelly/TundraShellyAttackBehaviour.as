class UTundraShellyAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UTundraShellySettings ShellySettings;
	UBasicAIHealthComponent HealthComp;
	UTundraShellyShellComponent ShellComp;
	AHazeCharacter Character;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShellySettings = UTundraShellySettings::GetSettings(Cast<AHazeActor>(Owner));
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ShellComp = UTundraShellyShellComponent::GetOrCreate(Owner);
		Character = Cast<AHazeCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(ShellComp.bShelled)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ShellComp.bShelled)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.Z > Character.ActorLocation.Z + 100)
				continue;

			auto PlayerShape = Player.CapsuleComponent.GetCollisionShape(50);
			auto CharacterShape = Character.CapsuleComponent.GetCollisionShape(50);

			if(Overlap::QueryShapeOverlap(PlayerShape, Player.ActorTransform, CharacterShape, Character.ActorTransform, 0.01))
			{
				Player.DamagePlayerHealth(0.1);
				FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
				Dir.Z = 0.75;
				Player.AddMovementImpulse(Dir*1000);
			}
		}
	}
}

