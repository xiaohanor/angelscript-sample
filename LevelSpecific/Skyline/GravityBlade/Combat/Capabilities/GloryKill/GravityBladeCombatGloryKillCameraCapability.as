class UGravityBladeCombatGloryKillCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::PostWork;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UGravityBladeCombatUserComponent CombatComp;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombatCamera);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CombatComp.GloryKillCameraData.bMoveCustomPoint)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.GloryKillCameraData.bMoveCustomPoint)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CombatComp.GloryKillCameraData.TargetType == EGravityBladeGloryKillPOITargetType::InBetweenEnforcerPlayer)
		{
			FVector EnforcerLocation = CombatComp.GloryKillCameraData.TargetEnforcer.Mesh.GetSocketLocation(n"Hips");
			FVector PlayerLocation = Player.ActorLocation;

			CustomTargetSceneComponent.WorldLocation = Player.ActorLocation + (EnforcerLocation - PlayerLocation) * 0.5;
			CustomTargetSceneComponent.WorldRotation = Player.ActorRotation;
		}
		else if(CombatComp.GloryKillCameraData.TargetType == EGravityBladeGloryKillPOITargetType::EnforcerAlignBone)
		{
			CustomTargetSceneComponent.WorldTransform = CombatComp.GloryKillCameraData.TargetEnforcer.Mesh.GetSocketTransform(n"Align");
		}
		else if(CombatComp.GloryKillCameraData.TargetType == EGravityBladeGloryKillPOITargetType::InBetweenEnforcerAlignBonePlayer)
		{
			FVector EnforcerLocation = CombatComp.GloryKillCameraData.TargetEnforcer.Mesh.GetSocketLocation(n"Align");
			FVector PlayerLocation = Player.ActorLocation;

			CustomTargetSceneComponent.WorldLocation = Player.ActorLocation + (EnforcerLocation - PlayerLocation) * 0.5;
			CustomTargetSceneComponent.WorldRotation = Player.ActorRotation;
		}
		else if(CombatComp.GloryKillCameraData.TargetType == EGravityBladeGloryKillPOITargetType::PlayerAlignBone)
		{
			CustomTargetSceneComponent.WorldTransform = Player.Mesh.GetSocketTransform(n"Align");
		}
		else if(CombatComp.GloryKillCameraData.TargetType == EGravityBladeGloryKillPOITargetType::PlayerHandBaseIK)
		{
			CustomTargetSceneComponent.WorldTransform = Player.Mesh.GetSocketTransform(n"HandBase_IK");
		}
		else if(CombatComp.GloryKillCameraData.TargetType == EGravityBladeGloryKillPOITargetType::InBetweenPlayerAlignBonePlayer)
		{
			FVector PlayerAlignBoneLocation = Player.Mesh.GetSocketLocation(n"Align");
			FVector PlayerLocation = Player.ActorLocation;

			CustomTargetSceneComponent.WorldLocation = Player.ActorLocation + (PlayerAlignBoneLocation - PlayerLocation) * 0.5;
			CustomTargetSceneComponent.WorldRotation = Player.ActorRotation;
		}
		else
			devError("Forgot to add case to handle poi target type using custom focus target point");
	}

	USceneComponent GetCustomTargetSceneComponent() const property
	{
		return CombatComp.GloryKillCameraData.CustomTargetSceneComponent;
	}
}

struct FGravityBladeCombatGloryKillCameraData
{
	bool bMoveCustomPoint = false;
	EGravityBladeGloryKillPOITargetType TargetType;
	AAISkylineEnforcerBase TargetEnforcer;
	USceneComponent CustomTargetSceneComponent;
}