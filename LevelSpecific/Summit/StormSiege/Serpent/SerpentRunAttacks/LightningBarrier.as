class ALightningBarrier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Start;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent End;

	UPROPERTY(DefaultComponent, Attach = Start)
	UBillboardComponent StartVisual;
	default StartVisual.SetWorldScale3D(FVector(2.0));

	UPROPERTY(DefaultComponent, Attach = End)
	UBillboardComponent EndVisual;
	default EndVisual.SetWorldScale3D(FVector(2.0));

	float Rate = 1.0;
	float Time;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Time -= DeltaSeconds;
		
		if (Time <= 0.0)
		{
			Time = Rate;
			FStormSiegeLightningStrikeParams Params;
			Params.Start = Start.WorldLocation;
			Params.End = End.WorldLocation;
			Params.BeamWidth = 0.15;
			Params.AttachComp = Root;
			UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, Params);
		}
	}
};