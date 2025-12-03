class AMoonGuardianPlatformsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "AnchorActor";
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	const float PlatformMoveSpeed = 500;

	UPROPERTY(EditInstanceOnly)
	TArray<AMoonGuardianDreamPlatform> Platforms;

	UPROPERTY(EditInstanceOnly)
	AMoonGuardianCat GuardianCat;

	TArray<FVector> TargetLocations;
	
	bool bPlatformsVisible = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GuardianCat = TListedActors<AMoonGuardianCat>().GetSingle();
		GuardianCat.OnAwake.AddUFunction(this, n"OnAwake");
		GuardianCat.OnSleep.AddUFunction(this, n"OnSleep");

		// for(auto Platform : Platforms)
		// {
		// 	TargetLocations.Add(Platform.ActorLocation);
		// 	Platform.RevealComp.TargetOpacity = 0;
		// }
	}

	UFUNCTION()
	private void OnSleep()
	{
		// for(int i = 0; i < Platforms.Num(); i++)
		// {
		// 	Platforms[i].RevealComp.TargetOpacity = 1;
		// }
	}

	UFUNCTION()
	private void OnAwake()
	{
		// for(int i = 0; i < Platforms.Num(); i++)
		// {
		// 	Platforms[i].RevealComp.TargetOpacity = 0;
		// }
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (ARevealablePlatform Platform : Platforms)
		{
			Debug::DrawDebugLine(Platform.ActorLocation, ActorLocation, FLinearColor::Green, 10.0);
		}		
	}
#endif
};