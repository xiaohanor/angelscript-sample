class ABattlefieldTankTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Turret;
	UPROPERTY(DefaultComponent, Attach = Turret)
	USceneComponent BarrelRotationRoot;
	UPROPERTY(DefaultComponent, Attach = BarrelRotationRoot)
	USceneComponent BarrelKickbackRoot;
	UPROPERTY(DefaultComponent, Attach = BarrelKickbackRoot)
	UStaticMeshComponent Barrel;
	UPROPERTY(DefaultComponent, Attach = Barrel)
	UBattlefieldProjectileComponent ProjectileComponent1;
	default ProjectileComponent1.bAutoBehaviour = false;
	UPROPERTY(DefaultComponent, Attach = Barrel)
	UBattlefieldProjectileComponent ProjectileComponent2;
	default ProjectileComponent2.bAutoBehaviour = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BattlefieldTankTurretTargetingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BattlefieldTankTurretFireCapability");

	float MinDistance = 35000.0;

	TArray<AHazePlayerCharacter> GetPlayersInRange()
	{
		TArray<AHazePlayerCharacter> Players;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < MinDistance)
				Players.Add(Player);
		}

		return Players;
	}
}