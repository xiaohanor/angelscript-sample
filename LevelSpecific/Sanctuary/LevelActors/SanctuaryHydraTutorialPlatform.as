class ASanctuaryHydraTutorialPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateCompLeft;

	UPROPERTY(DefaultComponent, Attach = TranslateCompLeft)
	UStaticMeshComponent PlatformMeshLeft;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateCompRight;

	UPROPERTY(DefaultComponent, Attach = TranslateCompRight)
	UStaticMeshComponent PlatformMeshRight;

	float XLeftvalue;
	float XRightvalue;

	UPROPERTY(EditAnywhere)
	AGrappleLaunchPoint GrappleLaunch;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleLaunch.AddActorDisable(this);
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		XLeftvalue = TranslateCompLeft.GetRelativeLocation().X;
		XRightvalue = TranslateCompRight.GetRelativeLocation().X;

		if(Math::IsNearlyEqual(XRightvalue, 0.0, 50.0)  && Math::IsNearlyEqual(XLeftvalue, 0.0, 50.0))
		{
			GrappleLaunch.RemoveActorDisable(this);
			
		}else
		{
			GrappleLaunch.AddActorDisable(this);
		}
		
	}
};