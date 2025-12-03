
UCLASS(Abstract)
class UWorld_Skyline_Nightclub_Alley_Interactable_PowerPlug_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartReturnToSpool(){}

	UFUNCTION(BlueprintEvent)
	void OnUnplugged(){}

	UFUNCTION(BlueprintEvent)
	void OnPlugged(){}

	UFUNCTION(BlueprintEvent)
	void OnThrown(){}

	UFUNCTION(BlueprintEvent)
	void OnGrabbed(){}

	UFUNCTION(BlueprintEvent)
	void OnImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnFinishReturnToSpool(){}

	/* END OF AUTO-GENERATED CODE */

	ASkylinePowerPlug Plug;
	
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter PlugEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Emitters")
	UHazeAudioEmitter CableEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Emitters")
	UHazeAudioEmitter SpoolEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Plug = Cast<ASkylinePowerPlug>(HazeOwner);
		SpoolEmitter.AudioComponent.SetWorldLocation(Plug.CableAttach.WorldLocation);
		SpoolEmitter.AudioComponent.DetachFromParent(true);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"PlugEmitter")
		{
			bUseAttach = true;
			return true;
		}

		bUseAttach = false;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!GetIsPlugOnSpool())
		{
			TArray<FAkSoundPosition> CableSoundPositions;

			for(auto Player : Game::GetPlayers())
			{	
				FVector ClosestPlayerPos;
				float ClosestDistSqrd = MAX_flt;

				for(auto& Particle : Plug.CableComp.Particles)
				{
					const float DistSqrd = Particle.Position.DistSquared(Player.ActorLocation);
					if(DistSqrd < ClosestDistSqrd)
					{
						ClosestDistSqrd = DistSqrd;
						ClosestPlayerPos = Particle.Position;
					}
				}

				CableSoundPositions.Add(FAkSoundPosition(ClosestPlayerPos));
				CableEmitter.AudioComponent.SetMultipleSoundPositions(CableSoundPositions);
			}
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Cable Length Normalized"))
	float GetCableLengthNormalized()
	{
		const float CurrDist = (Plug.ActorLocation - Plug.Origin.WorldLocation).Size();
		const float Dist =  CurrDist / Plug.CableLength;
		return Dist;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Plug Impact Physmat"))
	UPhysicalMaterialAudioAsset GetPlugImpactPhysMat()
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		FVector Normal = Plug.MoveComp.PreviousVelocity.GetSafeNormal();

		return Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(Plug.GetActorLocation(), Normal, Trace).AudioAsset);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Time To Spool"))
	float GetTimeToSpool()
	{
		return Plug.LerpDuration;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Plug Thrown"))
	bool GetIsPlugThrown()
	{
		return Plug.bThrown;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Plug Grabbed"))
	bool GetIsPlugGrabbed()
	{
		return Plug.GravityWhipResponseComp.IsGrabbed();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Plug On Spool"))
	bool GetIsPlugOnSpool()
	{
		return Plug.bIsSpooled;
	}
}