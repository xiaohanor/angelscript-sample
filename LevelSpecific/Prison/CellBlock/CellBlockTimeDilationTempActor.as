class ACellBlockTimeDilationTempActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(3.0);

	float MioTimeDilation = 1.0;
	float ZoeTimeDilation = 1.0;

	UFUNCTION(BlueprintCallable)
	void TimeDilatePlayer(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			MioTimeDilation = 0.1;
		else
			ZoeTimeDilation = 0.1;
		Player.SetActorTimeDilation(0.1, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MioTimeDilation = Math::FInterpConstantTo(MioTimeDilation, 1.0, DeltaTime, 0.18);
		ZoeTimeDilation = Math::FInterpConstantTo(ZoeTimeDilation, 1.0, DeltaTime, 0.18);

		Game::GetMio().SetActorTimeDilation(MioTimeDilation, this);
		Game::GetZoe().SetActorTimeDilation(ZoeTimeDilation, this);

		PrintToScreen("" + MioTimeDilation);
	}
}