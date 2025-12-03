class UTundraGnapeAnnoyedPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	float KnockingOffDuration = 0.0;

	TArray<UTundraGnatComponent> AnnoyingGnapes;

	TArray<FGnapeChainReactionParam> GnapesToKnockOff;

	void KnockOffAnnoyingGnapes(AHazeActor ThrownGnape, AHazeActor FirstHit, float MaxRedirection, float ImpulseHeight)
	{
		if (!ThrownGnape.HasControl())
			return;

		TArray<FGnapeChainReactionParam> Params;
		Params.SetNum(AnnoyingGnapes.Num());
		for (int i = 0; i < AnnoyingGnapes.Num(); i++)
		{
			Params[i].Gnape = AnnoyingGnapes[i];
			Params[i].DistanceToOriginator = FirstHit.ActorLocation.Distance(AnnoyingGnapes[i].Owner.ActorLocation);
		}
		Params.Sort(false);
		Params[0].Impulse = Gnape::GetImpactImpulse(ThrownGnape.ActorVelocity, MaxRedirection, ImpulseHeight);
		Params[0].Delay = 0.0;
		float ImpulseForce = Math::Max(Params[0].Impulse.Size2D(), 200.0);
		for (int i = 1; i < AnnoyingGnapes.Num(); i++)
		{
			FVector ChainReactionImpulse = (Params[i].Gnape.Owner.ActorLocation - FirstHit.ActorLocation).GetSafeNormal2D();
			ChainReactionImpulse *= ImpulseForce * Math::RandRange(0.8, 1.0);
			float RedirectLimit = MaxRedirection + Math::Min(Params[i].DistanceToOriginator * 0.05, 10.0);
			Params[i].Impulse = Gnape::GetImpactImpulse(ChainReactionImpulse, RedirectLimit, ImpulseHeight);
			Params[i].Delay = 0.35 * Params[i].DistanceToOriginator / ImpulseForce;
		}

		CrumbKnockOffGnapes(ThrownGnape, Params);	
	}

	UFUNCTION(CrumbFunction)
	void CrumbKnockOffGnapes(AHazeActor ThrownGnape, TArray<FGnapeChainReactionParam> Params)
	{
		for (FGnapeChainReactionParam Param : Params)
		{
			Param.Gnape.bAboutToBeKnockedOff = true;
		}

		int NumPreviousGnapes = GnapesToKnockOff.Num();
		GnapesToKnockOff.Append(Params);
		SetComponentTickEnabled(true);
		ThrownGnape.ActorVelocity *= 0.9;

		if (NumPreviousGnapes > 0)
		{	
			// Adjust delay for the new batch which was just added
			for (int i = NumPreviousGnapes; i < GnapesToKnockOff.Num(); i++)
			{
				GnapesToKnockOff[i].Delay += KnockingOffDuration;
			}			
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GnapesToKnockOff.Num() == 0)
		{
			// We're done knocking gnapes off, prepare for next batch
			KnockingOffDuration = 0.0;
			SetComponentTickEnabled(false);
			return;
		}

		KnockingOffDuration += DeltaTime;
		if (KnockingOffDuration < GnapesToKnockOff[0].Delay)
			return;

		GnapesToKnockOff[0].Gnape.KnockOff(GnapesToKnockOff[0].Impulse);
		GnapesToKnockOff.RemoveAt(0);
	}
}

struct FGnapeChainReactionParam
{
	UTundraGnatComponent Gnape;
	float DistanceToOriginator;
	FVector Impulse; 
	float Delay;

	int opCmp(FGnapeChainReactionParam Other) const
	{
		if (DistanceToOriginator < Other.DistanceToOriginator)
		 	return -1;
		else 
		 	return 1;
	}
}