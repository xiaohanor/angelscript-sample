UCLASS(Abstract)
class ASketchbook_Cloud : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0;
	
	AHazePlayerCharacter Zoe;
	AHazePlayerCharacter Mio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this,n"PlayerImpact");
		ImpactComp.OnAnyImpactByPlayerEnded.AddUFunction(this,n"PlayerImpactEnded");
	}

	UFUNCTION()
	private void PlayerImpactEnded(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
			Zoe = nullptr;

		if(Player.IsMio())
			Mio = nullptr;
	}

	UFUNCTION()
	private void PlayerImpact(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
			Zoe = Player;

		if(Player.IsMio())
			Mio = Player;

		if(Player.GetRawLastFrameTranslationVelocity().Z < -10)
		{
			FVector ImpactDirection;
			ImpactDirection =  TranslateComp.WorldLocation - Player.ActorLocation;
			ImpactDirection.Z *= 100;;
			ImpactDirection.Normalize(SMALL_NUMBER);
			ImpactDirection *= 100;
			TranslateComp.ApplyImpulse(Player.ActorLocation, ImpactDirection);
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Zoe != nullptr)
		{
			FVector ForceDirectionZoe;
			ForceDirectionZoe =  TranslateComp.WorldLocation - Zoe.ActorLocation;
			ForceDirectionZoe.Y *= -0.5;
			ForceDirectionZoe.Normalize(SMALL_NUMBER);
			ForceDirectionZoe *= 2;

			TranslateComp.ApplyImpulse(Zoe.ActorLocation, ForceDirectionZoe);
			// RotateComp.ApplyImpulse(Zoe.ActorLocation, ForceDirectionZoe*0.5);
		}

		if(Mio != nullptr)
		{
			
			FVector ForceDirectionMio;
			ForceDirectionMio =  TranslateComp.WorldLocation - Mio.ActorLocation;
			ForceDirectionMio.Y *= -0.5;
			ForceDirectionMio.Normalize(SMALL_NUMBER);
			ForceDirectionMio *= 2;

			TranslateComp.ApplyImpulse(Mio.ActorLocation, ForceDirectionMio);
			// RotateComp.ApplyImpulse(Mio.ActorLocation, ForceDirectionMio*0.5);
		}

		FVector BobForce = FVector(0,0, Math::Sin(GameTimeSinceCreation-BobOffset));

		TranslateComp.ApplyImpulse(GetActorLocation(),BobForce);

	}
};
