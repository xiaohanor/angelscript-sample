
UCLASS(Abstract)
class UCharacter_Enemy_Island_Shared_RedBlueForceField_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	UIslandForceFieldComponent ForceFieldComp;
	UIslandForceFieldStateComponent ForceFieldStateComp;

	UFUNCTION(BlueprintEvent)
	void OnForceFieldActivated() {};
	
	UFUNCTION(BlueprintEvent)
	void OnForceFieldBreak() {};

	UFUNCTION(BlueprintEvent)
	void OnBulletImpacted() {};

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Force Field Integrity"))
	float GetForceFieldIntegrity()
	{
		return ForceFieldComp.Integrity;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		ComponentName = n"ForceFieldComp";
		bUseAttach = true;
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{ 
		ForceFieldComp = UIslandForceFieldComponent::Get(HazeOwner);
		ForceFieldStateComp = UIslandForceFieldStateComponent::Get(HazeOwner);
		GrenadeResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::Get(HazeOwner);
	} 

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//GrenadeResponseComp.OnStartDetonating.AddUFunction(this, n"OnForceFieldDetonated");
		ForceFieldComp.OnComponentHit.AddUFunction(this, n"OnImpact");
		ForceFieldComp.OnDepleted.AddUFunction(this, n"OnForceFieldDepleted");
		
		if(ForceFieldComp.IsFull())	
			OnForceFieldActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrenadeResponseComp.OnStartDetonating.UnbindObject(this);
		ForceFieldComp.OnComponentHit.UnbindObject(this);
	}

	UFUNCTION()
	void OnImpact(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, const FHitResult&in HitResult)	
	{
			
	}

	UFUNCTION(NotBlueprintCallable)
	void OnForceFieldDepleted()
	{
		//if(ForceFieldStateComp.IsActive())
		OnForceFieldBreak();
	}

	// UFUNCTION(NotBlueprintCallable)
	// void OnForceFieldDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	// {
	// 	if(ForceFieldStateComp.IsActive())
	// 		OnForceFieldBreak();
	// }

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Force Field Is Red"))
	bool GetForceFieldIsRed()
	{
		return ForceFieldComp.CurrentType == EIslandForceFieldType::Red;
	}
}