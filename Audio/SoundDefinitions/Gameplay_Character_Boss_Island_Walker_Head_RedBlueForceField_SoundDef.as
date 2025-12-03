
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Head_RedBlueForceField_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AIslandWalkerHead Head;
	AIslandWalkerHeadStumpTarget GetHeadTarget() const property
	{
		return Head.StumpRoot.Target;
	}
	
	UFUNCTION(BlueprintEvent)
	void OnForceFieldBreak(bool bWasRed) {};

	UFUNCTION(BlueprintEvent)
	void OnBulletImpacted() {};

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Force Field Integrity"))
	float GetForceFieldIntegrity()
	{
		return HeadTarget.ForceFieldComp.Integrity;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		auto WalkerHead = Cast<AIslandWalkerHead>(HazeOwner);
		TargetActor = WalkerHead.StumpRoot.Target;
		ComponentName = n"ForceFieldComp";
		bUseAttach = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return HeadTarget.bIsPoweredUp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return HeadTarget.bIsPoweredUp == false;
	}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{ 
		Head = Cast<AIslandWalkerHead>(HazeOwner);
	} 

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HeadTarget.GrenadeResponseComp.OnStartDetonating.AddUFunction(this, n"OnForceFieldDetonated");
		HeadTarget.ForceFieldComp.OnComponentHit.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HeadTarget.GrenadeResponseComp.OnStartDetonating.UnbindObject(this);
		HeadTarget.ForceFieldComp.OnComponentHit.UnbindObject(this);
	}

	UFUNCTION()
	void OnImpact(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, const FHitResult&in HitResult)	
	{
		if(OtherActor.IsA(AIslandRedBlueWeaponBullet))
		{

		}			
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBulletImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(HeadTarget.bForceFieldBreached == false)
			OnBulletImpacted();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnForceFieldDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		const bool bWasRed = Data.GrenadeOwner.IsMio();
		OnForceFieldBreak(bWasRed);		
	}
}