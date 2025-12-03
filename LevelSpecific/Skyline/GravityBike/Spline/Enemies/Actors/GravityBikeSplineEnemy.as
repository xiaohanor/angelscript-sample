#if !RELEASE
namespace DevToggleGravityBikeSpline
{
	const FHazeDevToggleBool DisableEnemies;
};
#endif

enum EGravityBikeSplineEnemyFireType
{
	Missile,
	Rifle,
};

UCLASS(Abstract, HideCategories = "Rendering Actor Cooking DataLayers")
class AGravityBikeSplineEnemy : AHazeActor
{
	access ActivateEnemiesTriggerComp = protected, UGravityBikeSplineActivateEnemiesTriggerComponent;

	UPROPERTY(EditAnywhere, Category = "GravityBikeSpline Enemy")
	bool bStartActivated = false;

	UPROPERTY(EditAnywhere, Category = "GravityBikeSpline Enemy")
	bool bDisableWhenDeactivated = true;

	UPROPERTY(EditAnywhere, Category = "GravityBikeSpline Enemy")
	bool bDisableDuringCutscenes = true;

	TSet<FInstigator> DeactivateInstigators;
	
	private float EnabledStartTime = -1;
	private bool bBlockingFire = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		DevToggleGravityBikeSpline::DisableEnemies.MakeVisible();
#endif

		if(bStartActivated)
		{
			Activate(this);
		}
		else
		{
			Deactivate(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.PersistentValue("Start Activated", bStartActivated)
			.Value("Enabled Start Time", EnabledStartTime)
			.Value("Blocking Fire", bBlockingFire)
		;

		if(DevToggleGravityBikeSpline::DisableEnemies.IsEnabled() && IsActive())
			Deactivate(this);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled() final
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.RemoveActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled() final
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.AddActorDisable(this);
		}
	}

	bool IsActive() const
	{
		return DeactivateInstigators.IsEmpty();
	}

	float GetEnabledDuration() const
	{
		if(!IsActive())
			return 0;

		return Time::GetGameTimeSince(EnabledStartTime);
	}

	protected void Activate(FInstigator Instigator)
	{
#if !RELEASE
		if(DevToggleGravityBikeSpline::DisableEnemies.IsEnabled())
			return;
#endif

		const bool bWasInactive = !IsActive();

		DeactivateInstigators.Remove(Instigator);

		if(bDisableWhenDeactivated)
			RemoveActorDisable(Instigator);

		if((bWasInactive && IsActive()) || !HasActorBegunPlay())
			OnActivated();
	}

	void Deactivate(FInstigator Instigator)
	{
		if(IsActive())
		{
			if(HasActorBegunPlay())
				OnDeactivated();
		}

		DeactivateInstigators.Add(Instigator);

		if(!bDisableWhenDeactivated)
			return;

		if(IsActorDisabledBy(Instigator))
			return;

		AddActorDisable(Instigator);
	}

	protected void OnActivated()
	{
		EnabledStartTime = Time::GameTimeSeconds;
	}

	protected void OnDeactivated()
	{
	}

	access:ActivateEnemiesTriggerComp
	void ActivateFromActivateEnemiesTrigger(UGravityBikeSplineActivateEnemiesTriggerComponent TriggerComp)
	{
		if(IsActive())
			return;

		Activate(this);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateFromProgressPoint(float Offset = -1000)
	{
		if(IsActive())
			return;

		Activate(this);

		auto SplineMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(this);
		if(SplineMoveComp != nullptr)
		{
			SplineMoveComp.SnapSplinePositionToClosestToGravityBike(Offset - SplineMoveComp.LeadAmount);

			const FTransform WorldTransform = SplineMoveComp.GetSplineTransform();
			SetActorLocationAndRotation(WorldTransform.Location, WorldTransform.Rotation);
		}
	}

	UPrimitiveComponent GetCollider() const
	{
		// Override in AS child classes
		return BP_GetCollider();
	}

	UFUNCTION(BlueprintEvent)
	protected UPrimitiveComponent BP_GetCollider() const
	{
		// Override in BP child classes
		return nullptr;
	}
}