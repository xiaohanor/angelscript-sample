event void FAllBirthdayCandlesLitSignature(AHazePlayerCharacter Player);

UCLASS(NotBlueprintable)
class ADentistBirthdayCandleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY()
	FAllBirthdayCandlesLitSignature OnAllBirthdayCandlesLit;

	UPROPERTY(EditInstanceOnly)
	AHazeSphere HazeSphereActor;

	FHazeTimeLike DarkHazeTimeLike;
	default DarkHazeTimeLike.Duration = 5.0;
	default DarkHazeTimeLike.UseSmoothCurveZeroToOne();

	TArray<ADentistBirthdayCandle> Candles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkHazeTimeLike.BindUpdate(this, n"DarkHazeTimeLikeUpdate");
	}

	UFUNCTION()
	private void DarkHazeTimeLikeUpdate(float CurrentValue)
	{
		HazeSphereActor.HazeSphereComponent.SetOpacityValue(CurrentValue * 2.5);
	}

	UFUNCTION()
	private void HandleCandleLit(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		Print("HandleCandleLit");

		bool bAllLit = GetLitCandleCount() == Candles.Num();

		if (bAllLit)
		{
			Print("CrumbAllLit");
			CrumbAllLit(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAllLit(AHazePlayerCharacter Player)
	{
		OnAllBirthdayCandlesLit.Broadcast(Player);

		Timer::SetTimer(this, n"HazeDarken", 1.0);
		
		for (auto Candle : Candles)
			Candle.bStayLit = true;
	}

	int GetLitCandleCount() const
	{
		int LitCandles = 0;

		for(auto Candle : Candles)
		{
			if(Candle.IsLit())
				LitCandles++;
		}

		return LitCandles;
	}

	UFUNCTION()
	private void HazeDarken()
	{
		DarkHazeTimeLike.Play();
	}
};