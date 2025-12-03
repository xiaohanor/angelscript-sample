class AArenaHomingBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BombRoot;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	USceneComponent ShellRoot;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	AHazePlayerCharacter TargetPlayer;
	bool bMagnetized = false;

	TArray<UStaticMeshComponent> Shells;

	float ShellOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");
		MagneticFieldResponseComp.OnPush.AddUFunction(this, n"MagnetPush");

		TargetPlayer = Math::RandBool() ? Game::Mio : Game::Zoe;

		ShellRoot.GetChildrenComponentsByClass(UStaticMeshComponent, false, Shells);
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		
	}

	UFUNCTION()
	private void MagnetPush(FMagneticFieldData Data)
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector Dir = (TargetPlayer.ActorCenterLocation - ActorLocation).GetSafeNormal();

		Debug::DrawDebugLine(ActorLocation, TargetPlayer.ActorCenterLocation, FLinearColor::Red);

		if (HackingComp.bHacked)
			return;

		float CounterForce = 0.0;
		if (Game::Zoe.IsAnyCapabilityActive(n"MagneticFieldPush"))
		{
			float Dist = ActorLocation.Distance(TargetPlayer.ActorCenterLocation);
			CounterForce = Math::GetMappedRangeValueClamped(FVector2D(200.0, 500.0), FVector2D(750.0, 0.0), Dist);

			for (UStaticMeshComponent CurShell : Shells)
			{
				CurShell.SetRelativeLocation((CurShell.ForwardVector * 35.0) + (-CurShell.RightVector * 35.0) + (CurShell.UpVector * 35.0));
			}
		}
		else
		{
			for (UStaticMeshComponent CurShell : Shells)
			{
				CurShell.SetRelativeLocation(FVector::ZeroVector);
			}
		}

		FVector DeltaMove = Dir * (500.0 - CounterForce) * DeltaTime;
		SetActorLocation(ActorLocation + DeltaMove);
	}
}