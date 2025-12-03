
class UTundraShellyDamageCapability : UHazeCapability
{	
	UTundraShellySettings ShellySettings;
	UBasicAIHealthComponent HealthComp;
	UTundraShellyShellComponent ShellComp;
	AHazeCharacter Character;
	AHazePlayerCharacter DamagingPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShellySettings = UTundraShellySettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ShellComp = UTundraShellyShellComponent::GetOrCreate(Owner);
		Character = Cast<AHazeCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(DamagingPlayer != nullptr)
			return;

		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.Z < Character.ActorLocation.Z + 100)
				continue;
			if(Player.ActorVelocity.Z > 0)
				continue;

			auto PlayerShape = Player.CapsuleComponent.GetCollisionShape(50);
			auto CharacterShape = Character.CapsuleComponent.GetCollisionShape(50);

			if(Overlap::QueryShapeOverlap(PlayerShape, Player.ActorTransform, CharacterShape, Character.ActorTransform, 0.01))
			{
				ShellComp.EnterShell();
				DamagingPlayer = Player;
				Player.AddMovementImpulse(Player.ActorUpVector * (500 + Math::Abs(Player.ActorVelocity.Z)));
				Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
				Timer::SetTimer(this, n"ClearBlock", 0.1);
				return;
			}
		}
	}

	UFUNCTION()
	private void ClearBlock()
	{
		if(DamagingPlayer != nullptr)
		{
			DamagingPlayer.UnblockCapabilities(PlayerMovementTags::Grapple, this);
			DamagingPlayer = nullptr;
		}
	}
}