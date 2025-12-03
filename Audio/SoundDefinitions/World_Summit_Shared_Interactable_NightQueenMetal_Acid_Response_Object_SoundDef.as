UCLASS(Abstract)
class UWorld_Summit_Shared_Interactable_NightQueenMetal_Acid_Response_Object_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFullyMelted(){}

	UFUNCTION(BlueprintEvent)
	void OnAcidHit(FAcidHit AcidHit){}

	UFUNCTION(BlueprintEvent)
	void OnStartDissolve(){}

	/* END OF AUTO-GENERATED CODE */

	UStaticMeshComponent MeshComp;
	UAcidResponseComponent AcidComp;

	private TArray<FAkSoundPosition> SoundPositions;
	default SoundPositions.SetNum(2);

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter AcidEnvironmentImpactEmitter;

	private bool bCanActivate = false;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	bool bAcidActive = false;

	UPROPERTY(BlueprintReadOnly)
	ANightQueenMetal MetalObject;

	UPROPERTY(BlueprintReadOnly)
	float TimeToMelt = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float TimeToDissolve = 0.0;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MetalObject = Cast<ANightQueenMetal>(HazeOwner);

		AcidComp = UAcidResponseComponent::Get(HazeOwner);
		if(!devEnsure(AcidComp != nullptr, f"No AcidResponseComponent found for SoundDef: {GetName()}"))
			return;

		MeshComp = UStaticMeshComponent::Get(HazeOwner);
		if(!devEnsure(MeshComp.CollisionEnabled != ECollisionEnabled::NoCollision, f"No collision set for {HazeOwner.GetName()} - Query is needed for SoundDef to function!"))
			return;

		bCanActivate = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bCanActivate)
			return false;

		if(!MetalObject.bHandleRegrowth && MetalObject.DissolveAlphaTarget == 1.0)
			return false;

		return bCanActivate;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MetalObject.bHandleRegrowth && MetalObject.DissolveAlphaTarget == 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AcidComp.OnBeginInsideAcid.UnbindObject(this);
		AcidComp.OnEndInsideAcid.UnbindObject(this);
		AcidComp.OnAcidHit.UnbindObject(this);
		AcidComp.OnAcidTick.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(MetalObject != nullptr && TimeToMelt == 0.0)
		{
			TimeToMelt = MetalObject.CurrentSettings.MeltingSpeed / 3.0; // Static 3.0 multiplier is applied in melting capability, so we need to counteract it here......
			TimeToDissolve = MetalObject.CurrentSettings.DissolvingSpeed;
		}

		if(!bAcidActive)
			return;

		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestPlayerPos;
			const float Dist = MeshComp.GetClosestPointOnCollision(Player.ActorLocation, ClosestPlayerPos);
			if(Dist < 0)
				ClosestPlayerPos = MeshComp.WorldLocation;

			SoundPositions[int(Player.Player)].SetPosition(ClosestPlayerPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
	}
}