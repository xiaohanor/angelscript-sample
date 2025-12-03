UCLASS(Abstract)
class AAISummitObelisk : ABasicAIGroundMovementCharacter
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ShieldComp;
	default ShieldComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default ShieldComp.bCanEverAffectNavigation = false;

	UPROPERTY(EditAnywhere)
	TArray<AAISummitWard> ObeliskWards;

	UPROPERTY(EditAnywhere)
	TArray<AAISummitObeliskWeakpoint> ObeliskWeakpoints;

	int WardsKilled;

	int WeakpointsKilled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if (ObeliskWeakpoints.Num() > 0)
		{
			for (AAISummitObeliskWeakpoint Weakpoint : ObeliskWeakpoints)
			{
				Weakpoint.AcidTailBreakComp.OnBrokenByTail.AddUFunction(this, n"OnBrokenByTail");
			}
		}

		if (ObeliskWeakpoints.Num() > 0)
		{
			for (AAISummitWard Ward : ObeliskWards)
			{
				Ward.OnObeliskWardKilled.AddUFunction(this, n"OnWardKilled");
				FSummitActivateWardLinkParams Params;
				Params.Ward = Ward;
				Params.AttachComp = RootComponent;
				UAISummitObeliskEffectsHandler::Trigger_InitiateObeliskWardLink(this, Params);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UAISummitObeliskEffectsHandler::Trigger_SetObeliskWardLinks(this);
	}

	UFUNCTION()
	void OnWardKilled(AHazeActor KilledWard)
	{
		WardsKilled++;
		FSummitDeactivateWardLinkParams Params;
		Params.Ward = KilledWard;
		UAISummitObeliskEffectsHandler::Trigger_DeactivateObeliskWardLink(this, Params);

		if (WardsKilled >= ObeliskWards.Num())
		{
			ActivateObelisk();
		}
	}

	void ActivateObelisk()
	{
		ShieldComp.SetHiddenInGame(true);

		for (AAISummitObeliskWeakpoint Weakpoint : ObeliskWeakpoints)
		{
			Weakpoint.ActivateObeliskWeakpoint();
		}
	}

	UFUNCTION()
	void OnBrokenByTail(FOnBrokenByTailParams Params)
	{
		WeakpointsKilled++;

		if (WeakpointsKilled >= ObeliskWeakpoints.Num())
		{
			KillObelisk();
		}
	}

	void KillObelisk()
	{
		FSummitObeliskDeathParams Params;
		Params.Location = ActorLocation;
		Params.Rotation = ActorRotation;
		UAISummitObeliskEffectsHandler::Trigger_DestroyObelisk(this, Params);
		DestroyActor();
	}
}