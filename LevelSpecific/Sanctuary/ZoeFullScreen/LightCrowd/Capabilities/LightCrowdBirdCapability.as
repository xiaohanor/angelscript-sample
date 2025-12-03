class ULightCrowdBirdCapability : UHazePlayerCapability
{
    default CapabilityTags.Add(LightCrowdTags::LightCrowd);
    default CapabilityTags.Add(LightCrowdTags::LightCrowdMioBird);
    default CapabilityTags.Add(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInFullScreen);

    ULightCrowdBirdComponent PlayerComp;
    ULightCrowdPlayerComponent LightCrowdComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = ULightCrowdBirdComponent::Get(Player);
        LightCrowdComp = ULightCrowdPlayerComponent::GetOrCreate(Game::Zoe);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(LightCrowdComp.State != ELightCrowdState::MioBird)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(LightCrowdComp.State != ELightCrowdState::MioBird)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.BlockCapabilities(n"DisablePlayer", this);

        Player.Mesh.AddComponentVisualsBlocker(this);
        Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);
        Player.BlockCapabilities(PlayerMovementTags::Jump, this);
        Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
        Player.BlockCapabilities(PlayerMovementTags::Dash, this);
        Player.BlockCapabilities(PlayerMovementTags::Sprint, this);

        PlayerComp.BirdMesh = UHazeSkeletalMeshComponentBase::GetOrCreate(Player, n"BirdMesh");
        PlayerComp.BirdMesh.SetRelativeLocation(FVector(0.0, 0.0, 100.0));
        PlayerComp.BirdMesh.SetRelativeScale3D(FVector(0.2));
        PlayerComp.BirdMesh.SetSkeletalMeshAsset(Settings.BirdMesh);

        PlayerComp.BirdNiagara = Niagara::SpawnLoopingNiagaraSystemAttached(Settings.BirdNiagara,  PlayerComp.BirdMesh);

		FVector SpawnLocation = GetRandomSpawnLocation();
		FRotator SpawnRotation = (LightCrowdComp.Owner.ActorLocation - SpawnLocation).Rotation();
		Player.SetActorLocationAndRotation(SpawnLocation, SpawnRotation);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(n"DisablePlayer", this);

        Player.Mesh.RemoveComponentVisualsBlocker(this);

		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);
        Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
        Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
        Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
        Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);

		PlayerComp.BirdMesh.DestroyComponent(PlayerComp.BirdMesh);
		PlayerComp.BirdMesh = nullptr;

		PlayerComp.BirdNiagara.DestroyComponent(PlayerComp.BirdNiagara);
		PlayerComp.BirdNiagara = nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        
    }

	FVector GetRandomSpawnLocation() 
    {
        const FVector2D RandomPoint2D = Math::GetRandomPointOnCircle();
        FVector RandomPoint = FVector(RandomPoint2D.X, RandomPoint2D.Y, 0.0);

        FVector PlayerLocation = Player.ActorLocation;
        PlayerLocation.Z = 0.0;

        return PlayerLocation + (FVector(RandomPoint.X * Settings.BirdSpawnDistance, RandomPoint.Y * Settings.BirdSpawnDistance, 0.0));
    }

    ULightCrowdSettings GetSettings() const property
    {
        return LightCrowdComp.Settings;
    }
}