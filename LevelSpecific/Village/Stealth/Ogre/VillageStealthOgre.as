event void FVillageStealthOgreThrowableHitEvent();

class AVillageStealthOgre : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;
	default CollisionComp.RelativeLocation = FVector(0.0, 0.0, 220.0);
	default CollisionComp.CapsuleHalfHeight = 220.0;
	default CollisionComp.CapsuleRadius = 100.0;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMeshComp;
	default SkelMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent AutoKillTrigger;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"VillageStealthOgreBoulderThrowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"VillageStealthOgreTurnAroundCapability");

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FVillageStealthOgreThrowableHitEvent OnHitByThrowable;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AVillageStealthOgreThrownBoulder> BoulderClass;
	AVillageStealthOgreThrownBoulder PrimaryBoulder;
	AVillageStealthOgreThrownBoulder SecondaryBoulder;
	AVillageStealthOgreThrownBoulder CurrentBoulder;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger ExclusionTrigger;

	FRotator OriginalRotation;
	FRotator TargetRotation;

	FVector AnimTargetLoc;

	float TurnedAroundDuration = 2.0;

	bool bTurnedAround = false;

	EVillageStealthOgreState CurrentState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AutoKillTrigger.OnPlayerEnter.AddUFunction(this, n"EnterKillTrigger");

		PrimaryBoulder = SpawnActor(BoulderClass, bDeferredSpawn = true);
		PrimaryBoulder.MakeNetworked(this, 0);
		FinishSpawningActor(PrimaryBoulder);
		PrimaryBoulder.AttachToComponent(SkelMeshComp, n"RightAttach");
		PrimaryBoulder.SetActorRelativeRotation(FRotator(0.0, -90.0, 90.0));
		PrimaryBoulder.OnPlayerKilled.AddUFunction(this, n"PlayerKilledByBoulder");
		CurrentBoulder = PrimaryBoulder;

		SecondaryBoulder = SpawnActor(BoulderClass, bDeferredSpawn = true);
		SecondaryBoulder.MakeNetworked(this, 1);
		FinishSpawningActor(SecondaryBoulder);
		SecondaryBoulder.AttachToComponent(SkelMeshComp, n"RightAttach");
		SecondaryBoulder.SetActorRelativeRotation(FRotator(0.0, -90.0, 90.0));
		SecondaryBoulder.OnPlayerKilled.AddUFunction(this, n"PlayerKilledByBoulder");
		SecondaryBoulder.AddActorDisable(SecondaryBoulder);
	}

	UFUNCTION()
	private void PlayerKilledByBoulder(AHazePlayerCharacter Player)
	{
		UVillageStealthOgreEffectEventHandler::Trigger_BoulderHitPlayer(Player);
	}

	UFUNCTION()
	private void EnterKillTrigger(AHazePlayerCharacter Player)
	{
		FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		Player.KillPlayer(FPlayerDeathDamageParams(DeathDir), DeathEffect);
	}

	void HitByThrowable()
	{
		if (bTurnedAround)
			return;

		if (CurrentState != EVillageStealthOgreState::Idle)
			return;

		if (HasControl())
			CurrentState = EVillageStealthOgreState::TurningAround;
	}

	void RespawnBoulder()
	{
		if (CurrentBoulder == PrimaryBoulder)
			CurrentBoulder = SecondaryBoulder;
		else
			CurrentBoulder = PrimaryBoulder;

		CurrentBoulder.RemoveActorDisable(CurrentBoulder);
		CurrentBoulder.AttachToComponent(SkelMeshComp, n"RightAttach");
		CurrentBoulder.SetActorRelativeRotation(FRotator(0.0, -90.0, 90.0));
	}
}

enum EVillageStealthOgreState
{
	Idle,
	TurningAround,
	TurningBack,
	Throwing,
}