class UDarkPortalPlayerCompanionCapabilty : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Companion");
	default BlockExclusionTags.Add(LightBird::Tags::LightBirdActiveDuringIntro);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDarkPortalUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Owner);

		FRotator ViewRot = Player.ViewRotation;
		FVector WatsonLocation = Player.ViewLocation - ViewRot.ForwardVector * 100.0 + ViewRot.RightVector * -200.0 + ViewRot.UpVector * 200.0;
		UserComp.Companion = SpawnActor(UserComp.CompanionClass, WatsonLocation, Player.ActorRotation, bDeferredSpawn = true, Level = Player.Level);
		UserComp.Companion.MakeNetworked(Player, n"DarkPortalCompanion");
		auto CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(UserComp.Companion);
		CompanionComp.Player = Player;
		CompanionComp.Portal = UserComp.Portal;
		CompanionComp.UserComp = UserComp;
		FinishSpawningActor(UserComp.Companion);
		UserComp.bCompanionEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Always active, block to disable companion
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.EnableCompanion(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.DisableCompanion(this);
	}
}
