struct FSummitObeliskDeathParams
{
	UPROPERTY()
	FVector Location;
	
	UPROPERTY()
	FRotator Rotation;
}

struct FSummitActivateWardLinkParams
{
	UPROPERTY()
	USceneComponent AttachComp;

	UPROPERTY()
	AHazeActor Ward;
}

struct FSummitDeactivateWardLinkParams
{
	UPROPERTY()
	AActor Ward;
}

struct FSummitObeliskWardLinkData
{
	UPROPERTY()
	AHazeActor Ward;

	UPROPERTY()
	AHazeActor Obelisk;

	UPROPERTY()
	UNiagaraComponent LinkComp;
}

UCLASS(Abstract)
class UAISummitObeliskEffectsHandler : UHazeEffectEventHandler
{

	UPROPERTY()
	UNiagaraSystem DeathSystem;

	UPROPERTY()
	UNiagaraSystem LinkSystem;

	TArray<FSummitObeliskWardLinkData> LinkSystemArray;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyObelisk(FSummitObeliskDeathParams Params) 
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathSystem, Params.Location, Params.Rotation);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void InitiateObeliskWardLink(FSummitActivateWardLinkParams Params)
	{
		FSummitObeliskWardLinkData Data;
		Data.LinkComp = Niagara::SpawnLoopingNiagaraSystemAttached(LinkSystem, Params.AttachComp);
		Data.Obelisk = Cast<AHazeActor>(Params.AttachComp.Owner);
		Data.Ward = Params.Ward;
		LinkSystemArray.Add(Data);
	}

	//Activate link for when/if wards are revived
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateObeliskWardLink(FSummitActivateWardLinkParams Params)
	{
		for (FSummitObeliskWardLinkData& Data : LinkSystemArray)
		{
			// if (Data.LinkComp.IsActive())
			// 	continue;

			if (Data.Ward == Params.Ward)
			{
				Data.LinkComp.Activate();
				break;
			}
		}
	}

	//Kill ward link
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeactivateObeliskWardLink(FSummitDeactivateWardLinkParams Params)
	{
		for (FSummitObeliskWardLinkData& Data : LinkSystemArray)
		{
			// if (!Data.LinkComp.IsActive())
			// 	continue;

			if (Data.Ward == Params.Ward)
			{
				Data.LinkComp.Deactivate();
				break;
			}
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SetObeliskWardLinks()
	{
		if (LinkSystemArray.Num() == 0)
			return;

		for (FSummitObeliskWardLinkData& Data : LinkSystemArray)
		{	
			if (!Data.LinkComp.IsActive())
				continue;

			if (Data.Ward == nullptr)
				continue;
			
			Data.LinkComp.SetVectorParameter(n"TetherStart", Data.Obelisk.ActorCenterLocation);
			Data.LinkComp.SetVectorParameter(n"TetherEnd", Data.Ward.ActorCenterLocation);
		}
	}
}