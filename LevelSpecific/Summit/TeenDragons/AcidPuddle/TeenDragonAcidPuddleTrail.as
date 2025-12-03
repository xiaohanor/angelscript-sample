
UCLASS(Abstract)
class ATeenDragonAcidPuddleTrail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent AcidProjectileCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAcidResponseComponent AcidResponseComponent;

	// How long will this traildrop live
	UPROPERTY(Category = "Settings")
	float LifeTime = 10;

	// The size the actor will have during its lifetime
	UPROPERTY(Category = "Settings")
	FHazeRange LifeTimeScale = FHazeRange(1, 1);

	// How far away from eachother the trail particles will spawn
	UPROPERTY(Category = "Settings")
	float SpawnDistance = 300;

	bool bIsHeadOfTrail = true;
	UTeenDragonAcidPuddleContainerComponent Container;
	ATeenDragonAcidPuddleTrail Next;
	ATeenDragonAcidPuddleTrail Prev;
	float LifeTimeLeft = 0;
	bool bHasExploded = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComponent.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{

	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAcidHit(FAcidHit AcidHit)
	{
		if(bHasExploded)
			return;
		
		ChainExplode(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LifeTimeLeft -= DeltaSeconds;

		// DEBUG
		//{
		// Debug::DrawDebugSphere(ActorLocation);
		// if(Next != nullptr)
		// 	Debug::DrawDebugArrow(ActorLocation + FVector(0, 0, 10), Next.ActorLocation + FVector(0, 0, 10), 50, FLinearColor::Green, 6);
		// if(Prev != nullptr)
		// 	Debug::DrawDebugArrow(ActorLocation, Prev.ActorLocation, 50, FLinearColor::Red, 6);
		//}

		if(bHasExploded)
		{
			if(LifeTimeLeft <= 0)
			{
				BP_OnExploded();

				FTeenDragonAcidPuddleTrailExplodeVFXData EffectData;
				EffectData.Location = ActorLocation;
				EffectData.bIsHeadOfTrail = bIsHeadOfTrail;
				UTeenDragonAcidPuddleVFXHandler::Trigger_OnTrailExplode(Container.Player, EffectData);

				// Trigger impact on all the response components
				auto ResponseContainer = FTeenDragonAcidPuddle::GetPuddleExplosionResponseComponentContainer();
				if(ResponseContainer != nullptr)
				{
					for(auto It : ResponseContainer.Components)
					{
						if(It.WorldLocation.DistSquared(ActorLocation) > Math::Square(It.ResponseRadius))
							continue;

						It.TriggerOnTrailExplosion(this);
					}
				}

				DestroyActor();
			}
		}
		else
		{
			if(LifeTimeLeft <= 0)
			{
				DestroyActor();
			}
			else
			{
				float Alpha = LifeTimeLeft / LifeTime;
				Alpha = Math::EaseOut(0, 1, Alpha, 1.5);
				float Size = LifeTimeScale.Lerp(Alpha);
				SetActorScale3D(FVector(Size));
			}
		}
	}

	void ChainExplode(float DelayToExplode)
	{
		if(bHasExploded)
			return;

		ExplodeSingle(DelayToExplode);

		// We need to explode the trail
		// over multiple frames
		const float ExplosionDelay = 0.1;

		if(Next != nullptr)
			Next.ChainExplode(DelayToExplode + ExplosionDelay);
		if(Prev != nullptr)
			Prev.ChainExplode(DelayToExplode + ExplosionDelay);
	}

	void ExplodeSingle(float DelayToExplode)
	{
		if(bHasExploded)
			return;
		
		bHasExploded = true;
		LifeTimeLeft = Math::Max(DelayToExplode, KINDA_SMALL_NUMBER);

		// We cut of this trail
		// if the dragon enters a new puddle
		// while this is exploding, those will not be linked
		if(bIsHeadOfTrail && Container != nullptr)
		{
			Container.CollectedAcidAlpha = 0;
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "On Exploded")
	private void BP_OnExploded() {};

}
