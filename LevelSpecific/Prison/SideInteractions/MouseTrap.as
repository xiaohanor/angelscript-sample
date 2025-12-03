UCLASS(Abstract)
class AMouseTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TrapRoot;

	UPROPERTY(DefaultComponent, Attach = TrapRoot)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = TrapRoot)
	USceneComponent CheeseRoot;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase MouseMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams AnimMouse;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ArmTrapTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SnapTrapTimeLike;

	FVector OriginalCheeseLoc;
	AHazePlayerCharacter InteractingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ArmTrapTimeLike.BindUpdate(this, n"UpdateArmTrap");
		ArmTrapTimeLike.BindFinished(this, n"FinishArmTrap");

		SnapTrapTimeLike.BindUpdate(this, n"UpdateSnapTrap");
		HideCheese();

		CheeseRoot.SetHiddenInGame(true, true);
		OriginalCheeseLoc = CheeseRoot.WorldLocation;
	}

	UFUNCTION()
	void ArmTrap(AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;

		CheeseRoot.AttachToComponent(TrapRoot);
		CheeseRoot.SetWorldLocation(OriginalCheeseLoc);

		HideCheese();
		Timer::SetTimer(this, n"AddCheeseToPlayerHand", 0.4);
		Timer::SetTimer(this, n"DetatchCheeseToPlayerHand", 2.3);
		ArmTrapTimeLike.PlayFromStart();

		UMouseTrapEventHandler::Trigger_OnArmTrap(this);
	}

	UFUNCTION()
	private void AddCheeseToPlayerHand()
	{
		CheeseRoot.AttachToComponent(InteractingPlayer.Mesh, n"Align");
		CheeseRoot.AddRelativeRotation(FRotator(-90, 0, 0));

		CheeseRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION()
	private void DetatchCheeseToPlayerHand()
	{
		CheeseRoot.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void HideCheese()
	{
		CheeseRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	private void UpdateArmTrap(float CurValue)
	{
		ArmRoot.SetRelativeRotation(FRotator(85.0 + CurValue, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishArmTrap()
	{
		MouseMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishMouse"), AnimMouse);
		MouseMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

		Timer::SetTimer(this, n"TakeCheese", 8.5);
		Timer::SetTimer(this, n"SnapTrap", 8.5);
	}

	UFUNCTION()
	private void FinishMouse()
	{
		MouseMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
	}

	UFUNCTION()
	private void TakeCheese()
	{
		CheeseRoot.AttachToComponent(MouseMesh, n"Align");
		CheeseRoot.AddRelativeRotation(FRotator(-90, 0, 0));
	}

	UFUNCTION()
	private void SnapTrap()
	{
		SnapTrapTimeLike.PlayFromStart();
		UMouseTrapEventHandler::Trigger_OnSnapTrap(this);
		Timer::SetTimer(this, n"PlayTrapSnapEffect", 0.16);
	}

	UFUNCTION()
	private void UpdateSnapTrap(float CurValue)
	{
		ArmRoot.SetRelativeRotation(FRotator(85.0 + CurValue, 0.0, 0.0));
	}

	UFUNCTION()
	private void PlayTrapSnapEffect()
	{
		BP_TrapSnapped();
	}

	UFUNCTION(BlueprintEvent)
	void BP_TrapSnapped() {}
}