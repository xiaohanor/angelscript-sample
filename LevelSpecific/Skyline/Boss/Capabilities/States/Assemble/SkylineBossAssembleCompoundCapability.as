struct FSkylineBossAssembleCompoundDeactivateParams
{
	bool bFinished = false;
};

class USkylineBossAssembleCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAssemble);

	// Assemble
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.IsStateActive(ESkylineBossState::Assemble))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineBossAssembleCompoundDeactivateParams& Params) const
	{
		if(!Boss.IsStateActive(ESkylineBossState::Assemble))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetState(ESkylineBossState::Assemble);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineBossAssembleCompoundDeactivateParams Params)
	{
		ResetCompoundNodes();

		if(Params.bFinished)
			Boss.SetState(ESkylineBossState::Combat);

		Boss.HeadPivot.SetWorldRotation(Boss.Mesh.GetBoneTransform(n"Body").Rotation);
		Boss.SyncedHeadPivotRotationComp.SetValue(Boss.HeadPivot.WorldRotation);
		Boss.SyncedHeadPivotRotationComp.TransitionSync(this);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(USkylineBossFeetFollowAnimationCapability())
		;
	}
}