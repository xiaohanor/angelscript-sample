event void FGarbageDispenserTrashDestroyed(AGarbageDispenserTrash Trash);

UCLASS(Abstract)
class AGarbageDispenser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_GarbageLoop;
	default FX_GarbageLoop.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USceneComponent FX_ImpactLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DispenserRoot;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot1;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot2;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot3;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot4;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot5;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot6;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot7;
	
	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent FlapRoot8;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	UPlayerLookAtTriggerComponent LookAtTrigger;
	default LookAtTrigger.Range = 10000.0;
	default LookAtTrigger.ViewCenterFraction = 0.85;

	UPROPERTY(DefaultComponent, Attach = DispenserRoot)
	USceneComponent TrashSpawnSpoint;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGarbageDispenserTrash> TrashClass;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenFlapsTimeLike;

	UPROPERTY(EditAnywhere)
	bool bUseLookAt = true;

	UPROPERTY(EditAnywhere)
	float TrashSpread = 500.0;

	UPROPERTY(EditAnywhere)
	float TrashFallDistance = 10000.0;

	TArray<USceneComponent> FlapRoots;

	bool bActivated = false;

	TArray<AGarbageDispenserTrash> AvailableTrash;

	FTimerHandle DropTrashTimerHandle;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (PlayerTrigger != nullptr)
			LookAtTrigger.TriggerVolume = PlayerTrigger;
		else
			LookAtTrigger.TriggerVolume = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlapRoots.Add(FlapRoot1);
		FlapRoots.Add(FlapRoot2);
		FlapRoots.Add(FlapRoot3);
		FlapRoots.Add(FlapRoot4);
		FlapRoots.Add(FlapRoot5);
		FlapRoots.Add(FlapRoot6);
		FlapRoots.Add(FlapRoot7);
		FlapRoots.Add(FlapRoot8);

		OpenFlapsTimeLike.BindUpdate(this, n"UpdateOpenFlaps");
		OpenFlapsTimeLike.BindFinished(this, n"FinishOpenFlaps");

		if (bUseLookAt)
			LookAtTrigger.OnBeginLookAt.AddUFunction(this, n"LookedAt");
		else
			LookAtTrigger.DisableTrigger();
	}

	UFUNCTION(NotBlueprintCallable)
	void LookedAt(AHazePlayerCharacter Player)
	{
		if (bActivated)
			return;

		bActivated = true;
		LookAtTrigger.DisableTrigger();

		OpenFlaps();
	}

	UFUNCTION(BlueprintCallable)
	void OpenFlaps()
	{
		if (OpenFlapsTimeLike.IsPlaying())
			return;

		bActivated = true;
		OpenFlapsTimeLike.Play();

		UGarbageDispenserEventHandler::Trigger_StartOpening(this);
	}

	UFUNCTION(BlueprintCallable)
	void CloseFlaps()
	{
		if (OpenFlapsTimeLike.IsPlaying())
			return;

		bActivated = false;
		OpenFlapsTimeLike.Reverse();

		DropTrashTimerHandle.ClearTimerAndInvalidateHandle();
		
		UGarbageDispenserEventHandler::Trigger_StopDroppingGarbage(this);
		UGarbageDispenserEventHandler::Trigger_StartClosing(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenFlaps(float CurValue)
	{
		float CurPitch = Math::Lerp(0.0, -89.0, CurValue);

		for (USceneComponent CurComp : FlapRoots)
		{
			FRotator Rot = CurComp.RelativeRotation;
			Rot.Pitch = CurPitch;
			CurComp.SetRelativeRotation(Rot);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenFlaps()
	{
		if (bActivated)
		{
			DropTrash();

			UGarbageDispenserEventHandler::Trigger_StopOpening(this);
			UGarbageDispenserEventHandler::Trigger_StartDroppingGarbage(this);
		}
		else
		{
			UGarbageDispenserEventHandler::Trigger_StopClosing(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DropTrash()
	{
		FVector SpawnLoc = TrashSpawnSpoint.WorldLocation;
		float XMod = Math::RandRange(-TrashSpread, TrashSpread);
		float YMod = Math::RandRange(-TrashSpread, TrashSpread);

		SpawnLoc.X += XMod;
		SpawnLoc.Y += YMod;

		AGarbageDispenserTrash Trash;
		if (AvailableTrash.Num() > 0)
		{
			Trash = AvailableTrash[0];
			AvailableTrash.RemoveAt(0);
		}
		else
		{
			Trash = SpawnActor(TrashClass, SpawnLoc);
			Trash.OnTrashDestroyed.AddUFunction(this, n"TrashDestroyed");
		}

		Trash.DropTrash(SpawnLoc, TrashFallDistance);

		DropTrashTimerHandle = Timer::SetTimer(this, n"DropTrash", Math::RandRange(0.1, 0.5));
	}

	UFUNCTION(NotBlueprintCallable)
	private void TrashDestroyed(AGarbageDispenserTrash Trash)
	{
		AvailableTrash.Add(Trash);
	}
}

UCLASS(Abstract)
class AGarbageDispenserTrash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TrashRoot;

	UPROPERTY(DefaultComponent, Attach = TrashRoot)
	UStaticMeshComponent TrashMesh;
	default TrashMesh.RelativeScale3D = FVector(1.5);

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> AvailableMeshes;

	UPROPERTY()
	FGarbageDispenserTrashDestroyed OnTrashDestroyed;

	bool bDropped = false;
	float DropSpeed = 3200.0;
	float RotationSpeed = 250.0;

	FVector StartPoint;
	float MaxFallDistance = 10000.0;

	void DropTrash(FVector Loc, float FallDist)
	{
		if (bDropped)
			return;

		MaxFallDistance = FallDist;

		SetActorLocation(Loc);

		UStaticMesh Mesh = AvailableMeshes[Math::RandRange(0, AvailableMeshes.Num() - 1)];
		TrashMesh.SetStaticMesh(Mesh);

		StartPoint = ActorLocation;
		RotationSpeed = Math::RandRange(250.0, 450.0);
		if (Math::RandBool())
			RotationSpeed *= -1;

		bDropped = true;
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bDropped)
			return;

		AddActorWorldRotation(FRotator(RotationSpeed * DeltaTime, RotationSpeed * 0.6 * DeltaTime, RotationSpeed * 1.5 * DeltaTime));
		AddActorWorldOffset(FVector(0.0, 0.0, -DropSpeed * DeltaTime));
		if (ActorLocation.Distance(StartPoint) >= MaxFallDistance)
			DestroyTrash();
	}

	void DestroyTrash()
	{
		bDropped = false;
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
		OnTrashDestroyed.Broadcast(this);
	}
}