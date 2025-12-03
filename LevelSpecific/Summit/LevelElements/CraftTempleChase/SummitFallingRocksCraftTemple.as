event void FonImpact();

class ASummitFallingRocksCraftTemple : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root )
	USceneComponent Meshroot;

	UPROPERTY(DefaultComponent, Attach = Meshroot )
	UNiagaraComponent RockImpactFX;

	UPROPERTY(DefaultComponent, Attach = Root )
	USceneComponent TargetRoot;

	UPROPERTY()
	FonImpact Impact;

	UPROPERTY(NotVisible)
	FVector StartLoc;
	UPROPERTY(NotVisible)
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = Meshroot.RelativeLocation;
		TargetLoc = TargetRoot.RelativeLocation;
	}

	UFUNCTION(BlueprintCallable)
	void BP_OnFinished()
	{
		Impact.Broadcast();
	}
};