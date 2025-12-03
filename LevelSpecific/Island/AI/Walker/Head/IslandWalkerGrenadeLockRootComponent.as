event void FGrenadeEventSignature(AIslandGrenadeLock Lock);

// Snippet that should be in AIIslandWalker if we want to use grenade locks:
	// UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "MioShield_Socket")
	// UIslandWalkerGrenadeLockRootComponent RedGrenadeLockRoot;
	// default RedGrenadeLockRoot.UsableByPlayer = EHazePlayer::Mio;
	// default RedGrenadeLockRoot.RelativeRotation = FRotator(-90.0, 0.0, 180.0);		
	// default RedGrenadeLockRoot.RelativeScale3D = FVector(0.75);		

	// UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "ZoeShield_Socket")
	// UIslandWalkerGrenadeLockRootComponent BlueGrenadeLockRoot;
	// default BlueGrenadeLockRoot.UsableByPlayer = EHazePlayer::Zoe;
	// default BlueGrenadeLockRoot.RelativeRotation = FRotator(-90.0, 0.0, 180.0);		
	// default BlueGrenadeLockRoot.RelativeScale3D = FVector(0.75);		

// Snippets from UIslandWalkerHeadDestroyedCapability
	// TArray<UIslandWalkerGrenadeLockRootComponent> LockRootComps;

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (LockRootComps.Num() == 0)
	// 		return false;
	// 	for (UIslandWalkerGrenadeLockRootComponent Root : LockRootComps)
	// 	{
	// 		if (!Root.bIsTriggered)
	// 			return false;
	// 	}
	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	...
		
	// 	Owner.AddActorDisable(this);
	// 	for (UIslandWalkerGrenadeLockRootComponent Root : LockRootComps)
	// 	{
	// 		Root.GrenadeLock.AddActorDisable(this);
	// 	}
	// }

// Snippets from UIslandWalkerHeadDetachIntroBehaviour
		// // Activate grenade locks
		// TArray<UIslandWalkerGrenadeLockRootComponent> LockRootComps;
		// Owner.GetComponentsByClass(LockRootComps);
		// TArray<AIslandGrenadeLock> Locks;
		// for (UIslandWalkerGrenadeLockRootComponent Root : LockRootComps)
		// {
		// 	if (Root.GrenadeLock == nullptr)
		// 		Root.SetupGrenadeLock(HeadComp.GrenadeLockClass);
		// 	Locks.Add(Root.GrenadeLock);
		// }

		// // We need a listener to connect the locks 
		// AIslandGrenadeLockListener DummyListener = SpawnActor(AIslandGrenadeLockListener, bDeferredSpawn = true, Level = Owner.Level);
		// DummyListener.Children = Locks;
		// DummyListener.MakeNetworked(Owner, n"DummyGrenadeLockListener");
		// FinishSpawningActor(DummyListener);

// UIslandWalkerHeadGrenadeDetonatedBehaviour
	// TArray<UIslandWalkerGrenadeLockRootComponent> LockRootComps;
	// 	Owner.GetComponentsByClass(LockRootComps);
	// 	for (UIslandWalkerGrenadeLockRootComponent LockRoot : LockRootComps)
	// 	{
	// 		LockRoot.OnGrenadeLockTriggered.AddUFunction(this, n"OnGrenadeLockTriggered");
	// 	}
	// UFUNCTION()
	// private void OnGrenadeLockTriggered(AIslandGrenadeLock Lock)
	// {
	// 	TriggeredTime = Time::GameTimeSeconds;
	// 	TriggeredLock = Lock;
	// }

// UIslandWalkerHeadGrenadeDetectionCapability
	// TPerPlayer<UIslandWalkerGrenadeLockRootComponent> RootComps;	

	// 	TArray<UIslandWalkerGrenadeLockRootComponent> GrenadeLockRoots;
	// 	Owner.GetComponentsByClass(GrenadeLockRoots);
	// 	for (AHazePlayerCharacter Player : Game::Players)
	// 	{
	// 		DetectedGrenades[Player] = nullptr;
	// 		RootComps[Player] = GrenadeLockRoots[(GrenadeLockRoots[0].UsableByPlayer == Player.Player) ? 0 : 1];
	// 	}

	// 	for (AHazePlayerCharacter Player : Game::Players)
	// 	{
	// 		if (RootComps[Player].GrenadeLock == nullptr)
	// 			return false;
	// 	}

	// 		RootComps[Player].GrenadeLock.GrenadeResponseComp.BlockImpactForPlayer(Player, this);

	// 	if (!Grenade.ActorLocation.IsWithinDist(RootComps[Player].WorldLocation, Settings.HeadLocksGrenadeDetectionRange))
	// 		return false;

	// 	UIslandWalkerGrenadeLockRootComponent RootComp = RootComps[Player];
	// 	RootComp.GrenadeLock.GrenadeResponseComp.UnblockImpactForPlayer(Player, this);
	// 	RootComp.OnGrenadeProperlyAttached.Broadcast(RootComp.GrenadeLock);	
	// 	UIslandWalkerHeadEffectHandler::Trigger_OnGrenadeHitLock(Owner, FIslandWalkerGrenadeLockParams(RootComp.GrenadeLock));

	//	RootComps[Player].GrenadeLock.GrenadeResponseComp.BlockImpactForPlayer(Player, this);



class UIslandWalkerGrenadeLockRootComponent : USceneComponent
{
	UPROPERTY()
	EHazePlayer UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	AIslandGrenadeLock GrenadeLock = nullptr;

	bool bIsTriggered = false;

	FGrenadeEventSignature OnGrenadeProperlyAttached;
	FGrenadeEventSignature OnGrenadeLockTriggered;

	UIslandWalkerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void SetupGrenadeLock(TSubclassOf<AIslandGrenadeLock> GrenadeLockClass)
	{
		GrenadeLock = SpawnActor(GrenadeLockClass, bDeferredSpawn = true, Level = Owner.Level);
		GrenadeLock.MakeNetworked(this, n"GrenadeLock");
		GrenadeLock.UsableByPlayer = UsableByPlayer;
		GrenadeLock.TargetComp.AutoAimMaxAngle = 12.0;
		GrenadeLock.TargetComp.AutoAimMaxAngleMinDistance = 2000.0;
		GrenadeLock.TargetComp.AutoAimMaxAngleAtMaxDistance = 4.0;
		GrenadeLock.TargetComp.MaximumDistance = 6000.0;
		GrenadeLock.TargetComp.TargetShape.Type = EHazeShapeType::Sphere;

		// Very generous detonation detection; response component will only be unblocked when a properly placed grenade has been detected 
		GrenadeLock.TargetComp.TargetShape.SphereRadius = Settings.HeadLocksGrenadeDetectionRange;
		GrenadeLock.GrenadeResponseComp.bTriggerRequiresGrenadeContact = false;
		GrenadeLock.GrenadeResponseComp.bIgnoreDetonationTrace = true;

		FinishSpawningActor(GrenadeLock);

		GrenadeLock.AttachToComponent(this, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		GrenadeLock.OnActivated.AddUFunction(this, n"OnTriggeredByGrenade");
		GrenadeLock.OnDeactivated.AddUFunction(this, n"OnRestored");
	}

	UFUNCTION()
	private void OnTriggeredByGrenade(AIslandGrenadeLock Lock)
	{
		// This is checked by death capability
		bIsTriggered = true;
		OnGrenadeLockTriggered.Broadcast(Lock);
		UIslandWalkerHeadEffectHandler::Trigger_OnGrenadeTriggerLock(Cast<AHazeActor>(Owner), FIslandWalkerGrenadeLockParams(Lock));
	}

	UFUNCTION()
	private void OnRestored(AIslandGrenadeLock Lock)
	{
		bIsTriggered = false;
	}
}

