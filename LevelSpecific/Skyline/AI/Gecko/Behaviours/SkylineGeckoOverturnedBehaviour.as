class USkylineGeckoOverturnedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	USkylineGeckoComponent GeckoComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;

	UBasicAIHealthComponent ThrownAtTargetHealthComp;

	USkylineGeckoSettings Settings;
	AHazeCharacter Character;
	bool bStarted;
	bool bFalling;
	bool bRecovering;
	bool bGrabbed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Character = Cast<AHazeCharacter>(Owner);

		auto WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");

		UGravityWhippableComponent::Get(Owner).OnImpact.AddUFunction(this, n"OnThrownImpact");
		HealthComp.OnStartDying.AddUFunction(this, n"OnDeath");

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		// We're being thrown by whip, note our target
		if (TargetComponent == nullptr)
			return;
		ThrownAtTargetHealthComp = UBasicAIHealthComponent::Get(TargetComponent.Owner);
	}

	UFUNCTION()
	private void OnThrownImpact()
	{
		// We got thrown by whip and have hit somethings, affect other geckos!
		HealthComp.TakeDamage(Settings.ThrownImpactDamage, EDamageType::Impact, Game::Zoe);
		OverturnOtherGeckos(Settings.HitByThrownGeckoRadius, Settings.HitByThrownGeckoDamage, Settings.DirectHitByThrownGeckoRadius, Settings.DirectHitByThrownGeckoDamage, Game::Zoe);
		ThrownAtTargetHealthComp = nullptr;
	}

	UFUNCTION()
	private void OnDeath(AHazeActor ActorBeingKilled)
	{
		OverturnOtherGeckos(Settings.DeathExplosionRadius, 0.0, 0.0, 0.0, HealthComp.LastAttacker);
	}

	void OverturnOtherGeckos(float Radius, float Damage, float DirectHitRadius, float DirectHitDamage, AHazeActor Instigator)
	{
		for (AHazeActor Other : GeckoComp.Team.GetMembers())
		{
			if (Other == nullptr)
				continue;
			if (Other == Owner)
				continue;
			if (!Other.ActorLocation.IsWithinDist(Owner.ActorLocation, Radius))
				continue;
			
			auto OtherGeckoComp = USkylineGeckoComponent::Get(Other);
			if (OtherGeckoComp != nullptr)
			{
				// skip geckos that are leaping to constrain
				auto OtherTargetComp = UBasicAITargetingComponent::Get(Other);
				if (OtherGeckoComp.bShouldConstrainAttackLeap.Get())
					continue;

				// Skip geckos that are constraining Zoe if attack came from delayed whip throw
				if (OtherGeckoComp.bIsConstrainingTarget && OtherTargetComp.HasValidTarget() && OtherTargetComp.Target == Game::Zoe && Instigator == Game::Zoe)
					continue;
			}

			// skip geckos that are invulnerable
			auto OtherHealthComp = UBasicAIHealthComponent::Get(Other);
			if (OtherHealthComp.IsInvulnerable())
				continue;

			if ((DirectHitDamage > 0.0) && IsDirectHit(OtherHealthComp, DirectHitRadius))
				OtherHealthComp.TakeDamage(DirectHitDamage, EDamageType::MeleeBlunt, Game::Zoe);
			else if (Damage > 0.0)
				OtherHealthComp.TakeDamage(Damage, EDamageType::MeleeBlunt, Game::Zoe);

			if (OtherGeckoComp == nullptr)
				continue;

			// Geckos get stunned and overturned
			OtherGeckoComp.OverturnedTime = Time::GameTimeSeconds;
			OtherGeckoComp.OverturningActor = Owner;
			OtherHealthComp.SetStunned();
			if (Instigator == Game::Zoe)
				OtherGeckoComp.bHitByThrownGecko = true;
		}
	}

	bool IsDirectHit(UBasicAIHealthComponent OtherHealthComp, float DirectHitRadius)
	{
		// More fun to knock geckos on splines off their perch to their doom than killing them outright
		if (OtherHealthComp.Owner.ActorUpVector.DotProduct(FVector::UpVector) < 0.9)
			return false;

		// Target of throw is much more likely to suffer direct damage		
		if (OtherHealthComp == ThrownAtTargetHealthComp)
		{
			if (OtherHealthComp.Owner.ActorLocation.IsWithinDist(Owner.ActorLocation, DirectHitRadius + 200.0))
				return true;
		}
		else if (OtherHealthComp.Owner.ActorLocation.IsWithinDist(Owner.ActorLocation, DirectHitRadius))
		{
			return true;
		}
		return false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		bGrabbed = false;
		GeckoComp.ClearWhipGrab(this);
		GeckoComp.OverturnedTime = -BIG_NUMBER;
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
						   TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if(!IsActive())
			return;
		bGrabbed = true;
		AnimComp.ClearFeature(Owner);
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!HealthComp.IsStunned())
			return false;
		if (Time::GetGameTimeSince(GeckoComp.OverturnedTime) > 0.5)
			return false;	
		if(bGrabbed)
			return false;
		if(GeckoComp.HealthComp.IsInvulnerable())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.OverturnedStartDuration + Settings.OverturnedDuration + Settings.OverturnedRecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GeckoComp.SetOverturned();
		bStarted = false;
		bFalling = false;
		bRecovering = false;
		bGrabbed = false;
		AnimComp.RequestFeature(FeatureTagGecko::Overturned, SubTagGeckoOverturned::EnterFalling, EBasicBehaviourPriority::Medium, this, Settings.OverturnedStartDuration);		
		USkylineGeckoEffectHandler::Trigger_OnOverturnedStart(Owner);
		GeckoComp.ApplyWhipGrab(true, EGravityWhipGrabMode::Sling, this);
		UMovementGravitySettings::SetGravityScale(Owner, Settings.OverturnedGravityScale, this);
		
		if (GeckoComp.OverturningActor != nullptr)
		{
			FVector PushDir = (Owner.ActorLocation - GeckoComp.OverturningActor.ActorLocation).GetSafeNormal2D() * 0.5 + FVector::UpVector * 0.5;
			float Force = GeckoComp.bHitByThrownGecko ? Settings.HitByThrownGeckoPushForce : Settings.DeathExplosionAIPushForce;
			MoveComp.AddPendingImpulse(PushDir * Force);
		}

		if(GeckoComp.OverturningDirection.IsSet())
		{
			FVector PushDir = GeckoComp.OverturningDirection.Value.GetSafeNormal2D() * 0.5 + FVector::UpVector * 0.5;
			float Force = GeckoComp.bHitByThrownGecko ? Settings.HitByThrownGeckoPushForce : Settings.DeathExplosionAIPushForce;
			MoveComp.AddPendingImpulse(PushDir * Force);
		}
		GeckoComp.OverturningDirection.Reset();

		GeckoConstrainingPlayer::StopConstraining(GeckoComp);

		HackFlipDuration = Math::RandRange(0.5, 1.0) * (Math::RandBool() ? -1.0 : 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		GeckoComp.ResetOverturned(bGrabbed);
		Character.Mesh.SetRelativeRotation(FRotator(0, 0, 0));
		USkylineGeckoEffectHandler::Trigger_OnOverturnedStop(Owner);

		if (!bGrabbed)
			GeckoComp.ClearWhipGrab(this);
		Owner.ClearSettingsByInstigator(this);

		GeckoComp.OverturnedTime  = -BIG_NUMBER;
		GeckoComp.OverturningActor = nullptr;
		HealthComp.ClearStunned();
		GeckoComp.bHitByThrownGecko = false;

		// Hack: restore mesh rot
		Cast<AHazeCharacter>(Owner).Mesh.RelativeRotation = FRotator::ZeroRotator;
	}

	float HackFlipDuration;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < HackFlipDuration)
		{
			// Flip one turn
			UHazeSkeletalMeshComponentBase Mesh = Cast<AHazeCharacter>(Owner).Mesh;
			FRotator Rot = Mesh.RelativeRotation;
			Rot.Roll += (360.0 / HackFlipDuration) * DeltaTime;
			Mesh.RelativeRotation = Rot;
		}

		if(ActiveDuration < Settings.OverturnedStartDuration)
			return;

		// This will rotate actor to match new gravity direction
		DestinationComp.RotateInDirection(Owner.ActorForwardVector);

		if (bRecovering)
			return;

		if(ActiveDuration > Settings.OverturnedStartDuration + Settings.OverturnedDuration)
		{
			bRecovering = true;
			AnimComp.RequestFeature(FeatureTagGecko::Overturned, SubTagGeckoOverturned::OverturnedRecover, EBasicBehaviourPriority::Medium, this, Settings.OverturnedRecoverDuration);
			return;
		}

		if(!bStarted)
		{
			bStarted = true;
			bFalling = true;
			if (Math::Abs(Owner.ActorUpVector.DotProduct(FVector::UpVector)) < 0.866)
				Owner.AddMovementImpulse(Owner.ActorUpVector * Settings.OverturnedAwayFromWallsPush); // Push away from vertical walls
			AnimComp.RequestFeature(FeatureTagGecko::Overturned, SubTagGeckoOverturned::FallingMh, EBasicBehaviourPriority::Medium, this);
		}

		if(bFalling && MoveComp.IsOnAnyGround())
		{
			AnimComp.RequestFeature(FeatureTagGecko::Overturned, SubTagGeckoOverturned::Overturned, EBasicBehaviourPriority::Medium, this);
			bFalling = false;
		}
	}
}