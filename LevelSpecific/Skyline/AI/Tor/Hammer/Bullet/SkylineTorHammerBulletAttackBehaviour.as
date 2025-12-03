class USkylineTorHammerBulletAttackBehaviour : UBasicBehaviour
{	
	USkylineTorHammerBulletComponent HammerBulletComp;
	USkylineTorHammerVolleyComponent VolleyComp;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	AHazeCharacter Character;

	private AHazeActor Target;
	float BaseAngle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HammerBulletComp = USkylineTorHammerBulletComponent::GetOrCreate(Owner);
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		UGravityBladeCombatResponseComponent BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!HammerBulletComp.bEnabled)
			return;
		Cooldown.Set(1);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!HammerBulletComp.bEnabled)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		LaunchWave();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();	
	}

	private void LaunchWave()
	{
		float Angle = 0;
		for(int i = 0; i < 4; i++)
		{
			Angle += 90;
			FVector Dir = FVector::ForwardVector.RotateAngleAxis(BaseAngle + Angle, FVector::UpVector);
			LaunchBullet(Dir);
		}
		BaseAngle += 15;
		Cooldown.Set(0.5);
	}

	private void LaunchBullet(FVector Direction)
	{
		ASkylineTorHammerBullet HammerBullet = SpawnActor(HammerBulletComp.HammerBulletClass, Owner.ActorCenterLocation + Direction * 150, Level = Owner.Level);
		HammerBullet.ProjectileComp.AdditionalIgnoreActors.Add(Owner);
		HammerBullet.ProjectileComp.Launch(Direction * 50);
	}
}