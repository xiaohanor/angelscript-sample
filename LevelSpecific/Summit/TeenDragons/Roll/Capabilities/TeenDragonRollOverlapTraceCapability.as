asset TeenDragonRollOverlapTraceSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UTeenDragonRollOverlapTraceCapability);
}

class UTeenDragonRollOverlapTraceCapability : UHazePlayerCapability
{
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	default TickGroup = EHazeTickGroup::Gameplay;

	UTeenDragonRollComponent RollComp;

	UTeenDragonRollSettings RollSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollComp = UTeenDragonRollComponent::Get(Player);

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		if(RollComp == nullptr)
			return false;

		if(!RollComp.IsRolling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		if(!RollComp.IsRolling())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(RollComp != nullptr)
			return;

		RollComp = UTeenDragonRollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings ResponseCompTrace;
		FHazeTraceShape Shape = FHazeTraceShape::MakeShape(Player.CapsuleComponent.GetCollisionShape());
		ResponseCompTrace.UseShape(Shape);
		ResponseCompTrace.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
		auto Overlaps = ResponseCompTrace.QueryOverlaps(Player.CapsuleComponent.WorldLocation);
		TEMPORAL_LOG(Player, "Roll Overlap Trace").OverlapResults("Trace Overlaps", Overlaps);
		TArray<FTeenDragonRollResolverResponseComponentHitData> HitData;
		TArray<AActor> ActorsHit;
		for(auto Overlap : Overlaps)
		{
			auto ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Overlap.Actor);
			if(ResponseComp == nullptr)
				continue;

			if(!ResponseComp.bEnabled)
				continue;

			if(ActorsHit.Contains(Overlap.Actor))
				continue;

			if(ResponseComp.bIsPrimitiveParentExclusive
			&& !ResponseComp.ImpactWasOnParent(Overlap.Component))
				continue;
			
			FTeenDragonRollResolverResponseComponentHitData NewHitData;
			NewHitData.ResponseComp = ResponseComp;

			FRollParams RollParams;
			RollParams.DamageDealt = RollSettings.RollImpactDamage;
			RollParams.HitComponent = Overlap.Component;
			RollParams.PlayerInstigator = Player;
			RollParams.HitLocation = Overlap.Component.WorldLocation;

			float Speed = 0.0;
			FVector RollDir = FVector::ZeroVector;
			Player.ActorVelocity.ToDirectionAndLength(RollDir, Speed);
			RollParams.RollDirection = RollDir;
			RollParams.SpeedAtHit = Speed;
			FVector DirToOverlap = (Overlap.Actor.ActorLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			RollParams.SpeedTowardsImpact = Player.ActorVelocity.DotProduct(DirToOverlap);

			NewHitData.RollParams = RollParams;
			ActorsHit.Add(Overlap.Actor);
			HitData.Add(NewHitData);
		}
		if(!HitData.IsEmpty())
			RollComp.CrumbSendRollHits(HitData);
	}
};