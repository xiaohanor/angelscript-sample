UCLASS(Abstract)
class AKetchupBottle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent OverlapComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent BounceAreaOverlapComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SquishRootComp;

	UPROPERTY()
	UForceFeedbackEffect SquishFF;

	AHazePlayerCharacter Zoe;
	AHazePlayerCharacter Mio;

	bool bSquish = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
		{
			Zoe = Player;
			Zoe.PlayForceFeedback(SquishFF,this,0.2);
		}
		if(Player.IsMio())
		{
			Mio = Player;
			Mio.PlayForceFeedback(SquishFF,this,0.2);
		}
		bSquish = true;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSquish)
		{
			SquishRootComp.RelativeScale3D = Math::VInterpTo(SquishRootComp.RelativeScale3D,FVector(0.4,1,1),DeltaSeconds,15);
			if(SquishRootComp.RelativeScale3D.X <= 0.4)
			{
				if(Zoe != nullptr)
				{
					Zoe.AddMovementImpulse(FVector(0,0,1000 + Math::Sin(Time::GameTimeSeconds)*50));
					Zoe.PlayForceFeedback(SquishFF,this,0.5);
					Zoe = nullptr;
				}
				if (Mio != nullptr)
				{
					Mio.AddMovementImpulse(FVector(0,0,1000 + Math::Sin(Time::GameTimeSeconds)*-50));
					Mio.PlayForceFeedback(SquishFF,this,0.5);
					Mio = nullptr;
				}
				bSquish = false;
				OnImpact();
			}
		}
		else
		{
			SquishRootComp.RelativeScale3D = Math::VInterpTo(SquishRootComp.RelativeScale3D,FVector(1,1,1),DeltaSeconds,2);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnImpact(){}
};
