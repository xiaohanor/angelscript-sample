event void FonIntroComplete();

class AMeltdownBossPhaseThreeWorldGlitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WorldPortalMesh;

	UPROPERTY(EditAnywhere)
	UMaterialInstance WorldOne;

	UPROPERTY(EditAnywhere)
	UMaterialInstance WorldTwo;

	UPROPERTY(EditAnywhere)
	UMaterialInstance WorldThree;

	UPROPERTY()
	FonIntroComplete IntroDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void IntroComplete()
	{
		IntroDone.Broadcast();
	}
};