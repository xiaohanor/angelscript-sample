//Should be a container for functionality and data
//Class using this should manage the logic
event void FOnWeakpointHit();
event void FOnWeakpointTakeDamage(float Damage, AHazeActor Instigator, EDamageType DamageType);
event void FOnWeakpointDestroyed(UBasicAIWeakpointComponent Weakpoint);

enum EWeakpointPlayerTarget
{
	Both,
	Mio,
	Zoe
}

namespace Weakpoints
{
	UBasicAIWeakpointComponent FindWeakpointFromHit(UPrimitiveComponent PrimComp)
	{
		UBasicAIWeakpointComponent WeakComp = Cast<UBasicAIWeakpointComponent>(PrimComp.GetAttachParent());

		if (WeakComp != nullptr) 
			return WeakComp;

		return nullptr;
	}

	UBasicAIWeakpointComponent FindAndDamageWeakpointFromHit(UPrimitiveComponent PrimComp, float Damage, AHazeActor Instigator, EDamageType DamageType)
	{
		UBasicAIWeakpointComponent WeakComp = Cast<UBasicAIWeakpointComponent>(PrimComp.GetAttachParent());

		if (WeakComp != nullptr) 
		{
			WeakComp.DamageWeakpoint(Damage, Instigator, DamageType);
			return WeakComp;
		}

		return nullptr;
	}

	UBasicAIWeakpointComponent FindAndDestroyWeakpointFromHit(UPrimitiveComponent PrimComp)
	{
		UBasicAIWeakpointComponent WeakComp = Cast<UBasicAIWeakpointComponent>(PrimComp.GetAttachParent());

		if (WeakComp != nullptr) 
		{
			WeakComp.DestroyWeakpoint();
			return WeakComp;
		}

		return nullptr;
	}
}

//ATTACH COLLIDABLE PRIMITIVE UNDERNEATH
class UBasicAIWeakpointComponent : USceneComponent
{
	UPROPERTY()
	FOnWeakpointHit OnWeakpointHit;

	UPROPERTY()
	FOnWeakpointDestroyed OnWeakpointDestroyed;

	UPROPERTY()
	FOnWeakpointTakeDamage OnWeakpointTakeDamage;

	UPROPERTY(Category = "Setup")
	private bool bIsDestroyable = true;

	TArray<FInstigator> DisableInstigator;

	UTargetableComponent TargetableComp;

	//If it should start disabled
	UPROPERTY(Category = "Setup")
	bool bStartDisabled = false;

	private bool bIsEnabled;
	private bool bIsAlive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> SceneCompArray;
		GetChildrenComponents(true, SceneCompArray);

		for (USceneComponent Comp : SceneCompArray)
		{
			TargetableComp = Cast<UTargetableComponent>(Comp);
		}

		if (bStartDisabled)
			AddDisableWeakpoint(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	//Revive weakpoint and set to full health
	UFUNCTION()
	void ReviveWeakpoint()
	{
		bIsAlive = true;

		if (bStartDisabled)
			AddDisableWeakpoint(this);
		else
			AddEnableWeakpoint(this);
	}

	//If alive and enabled, deal damage
	UFUNCTION()
	void DamageWeakpoint(float Damage, AHazeActor DamageInstigator, EDamageType DamageType)
	{
		if (!bIsAlive)
			return;
		
		OnWeakpointHit.Broadcast();

		if (!bIsDestroyable)
			return;
		
		if (!bIsEnabled)
			return;

		OnWeakpointTakeDamage.Broadcast(Damage, DamageInstigator, DamageType);
	}

	//Kills the weakpoint
	UFUNCTION()
	void DestroyWeakpoint()
	{
		if (!bIsAlive)
			return;

		if (!bIsDestroyable)
			return;

		bIsAlive = false;
		OnWeakpointDestroyed.Broadcast(this);
		AddDisableWeakpoint(this);
	}

	//Enables weakpoint and any targetable components parented
	UFUNCTION()
	void AddEnableWeakpoint(FInstigator Instigator)
	{
		if (!bIsAlive)
			return;

		bIsEnabled = true;

		if (TargetableComp != nullptr)
		 	TargetableComp.Enable(n"Auto Aim Handled");

		DisableInstigator.Add(Instigator);
	}

	//Disables weakpoint and any targetable components parented
	UFUNCTION()
	void AddDisableWeakpoint(FInstigator Instigator) 
	{
		if (!bIsAlive)
			return;

		bIsEnabled = false;

		if (TargetableComp != nullptr)
		{
			Print("DISABLE TARGETABLE COMP: " + Owner.Name);
		 	TargetableComp.Disable(n"Auto Aim Handled");
		}
		
		DisableInstigator.Remove(Instigator);
	}

	//Checks if enabled
	UFUNCTION()
	bool IsWeakpointActive()
	{
		return bIsEnabled;
	}

	//Checks if alive
	UFUNCTION()
	bool IsAlive()
	{
		return bIsAlive;
	}
}