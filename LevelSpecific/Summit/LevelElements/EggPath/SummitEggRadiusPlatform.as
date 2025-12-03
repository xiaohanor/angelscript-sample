class ASummitEggRadiusPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	bool bIsInversed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void EnablePlatform()
	{
		BP_Activate();
	}

	UFUNCTION()
	void DisablePlatform()
	{
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}
};