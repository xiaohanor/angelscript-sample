class USummitCrystalSkullArmourComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASummitCrystalSkullArmour> ArmourClass;

	ASummitCrystalSkullArmour Armour;

	bool HasArmour() const
	{
		if (Armour == nullptr)
			return false;
		if (Time::GameTimeSeconds > Armour.DestroyedTime)
			return false;
		return true;
	}

	bool HadArmour(float WithinTime) const
	{
		if (Armour == nullptr)
			return false;
		if (Time::GetGameTimeSince(Armour.DestroyedTime) > WithinTime)
			return false;
		return true;
	}

	void CreateArmour()
	{
		Armour = SpawnActor(ArmourClass, WorldLocation, WorldRotation, NAME_None, true, Owner.Level);
		Armour.AttachToComponent(this, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, false);
		Armour.MakeNetworked(Owner, n"Armour");
		FinishSpawningActor(Armour);
	}

	void OnAcidHit(FAcidHit Hit)
	{
		Armour.AcidResponseComp.OnAcidHit.Broadcast(Hit);
	}
}

