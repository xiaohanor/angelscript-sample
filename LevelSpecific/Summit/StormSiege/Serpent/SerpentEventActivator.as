class USerpentEventActivatorRendererComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		USerpentEventActivatorDud Comp = Owner.GetComponentByClass(USerpentEventActivatorDud);

		if (Comp == nullptr)
			return;

		SetActorHitProxy();

		ASerpentEventActivator Activator = Cast<ASerpentEventActivator>(Comp.Owner);

		if (Activator == nullptr)
			return;

		SetRenderForeground(false);
		DrawWireSphere(Activator.ActorLocation, Activator.Radius, FLinearColor::LucBlue, 50.0, 16);
	}
}

class USerpentEventActivatorDud : USceneComponent
{

}

event void
FOnSerpentEventTriggered();

enum ESerpentEventActivatorTarget
{
	Serpent,
	Player,
	SpecificSerpent
}

UCLASS(NotBlueprintable)
class ASerpentEventActivator : AHazeActor
{
	UPROPERTY()
	FOnSerpentEventTriggered OnSerpentEventTriggered;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USerpentEventActivatorRendererComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	USerpentEventActivatorDud Dud;
#endif

	UPROPERTY(EditAnywhere)
	float Radius = 3000.0;

	UPROPERTY(EditAnywhere)
	ESerpentEventActivatorTarget Target;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Target==ESerpentEventActivatorTarget::SpecificSerpent"))
	ASerpentHead SpecificSerpentHead;

	// UPROPERTY(EditAnywhere)
	// bool bDebug;

	// Should this only trigger once, or every frame that it is valid
	UPROPERTY(EditAnywhere)
	bool bTriggerOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// SerpentHead = TListedActors<ASerpentHead>().GetSingle();

		// FOR TESTING ONLY
		//  TArray<ASerpentHead> SerpentArray;
		//  SerpentArray = TListedActors<ASerpentHead>().GetArray();
		//  SerpentHead = SerpentArray[1];
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Target == ESerpentEventActivatorTarget::Serpent)
		{
			bool bFoundValidTarget = false;
			auto SerpentArray = TListedActors<ASerpentHead>().GetArray();
			for (auto SerpentHead : SerpentArray)
			{
				if ((SerpentHead.ActorLocation - ActorLocation).Size() <= Radius)
				{
					bFoundValidTarget = true;
					break;
				}
			}

			if (!bFoundValidTarget)
				return;
		}
		else if (Target == ESerpentEventActivatorTarget::Player)
		{
			if ((Game::GetClosestPlayer(ActorLocation).ActorLocation - ActorLocation).Size() > Radius)
				return;
		}
		else if (Target == ESerpentEventActivatorTarget::SpecificSerpent)
		{
			if (SpecificSerpentHead == nullptr)
				return;
			if ((SpecificSerpentHead.ActorLocation - ActorLocation).Size() <= Radius)
				return;
		}

		OnSerpentEventTriggered.Broadcast();

		// we have triggered, so don't trigger any more
		if (bTriggerOnce)
		{
			AddActorDisable(n"InternalTickDisabler");
		}
	}

	UFUNCTION()
	void ResetEvent()
	{
		bTriggerOnce = false;
	}
}