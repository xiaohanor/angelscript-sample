
namespace Acid
{
	UAcidManagerComponent GetAcidManager()
	{
		return UAcidManagerComponent::GetOrCreate(Game::Mio);
	}

	void FireAcidProjectile(FAcidProjectileParams Params)
	{
		auto Manager = GetAcidManager();
		Manager.SpawnProjectile(Params);
	}

	void PlaceAcidPuddle(FAcidPuddleParams Params)
	{
		auto Manager = GetAcidManager();
		Manager.SpawnPuddle(Params);
	}

	bool IsAcidInsideShape(FHazeShapeSettings Shape, FTransform ShapeTransform)
	{
		auto Manager = GetAcidManager();
		return Manager.IsAcidInsideShape(Shape, ShapeTransform);
	}
}

struct FAcidAreaSphere
{
	int AreaId = 0;
	FVector Location;
	float Radius;
	TSet<AAcidPuddle> Puddles;
};

class UAcidManagerComponent : UActorComponent
{
	const float AREA_MAX_SIZE = 1500.0;

	TArray<AAcidProjectile> PooledProjectiles;
	TArray<AAcidProjectile> Projectiles;
	TArray<AAcidPuddle> PooledPuddles;
	TArray<FAcidAreaSphere> AcidAreas;

	int NextAreaId = 0;
	int UpdateArea = 0;

	AAcidProjectile SpawnProjectile(FAcidProjectileParams Params)
	{
		AAcidProjectile Projectile;
		if (PooledProjectiles.Num() != 0)
		{
			Projectile = PooledProjectiles[0];
			PooledProjectiles.RemoveAt(0);
			Projectile.RemoveActorDisable(this);
		}
		else
		{
			Projectile = SpawnActor(Params.ProjectileClass);
			Projectile.AcidManager = this;
		}

		Projectiles.Insert(Projectile, 0);
		Projectile.SetActorHiddenInGame(true);
		Projectile.Init(Params);

		return Projectile;
	}

	void ReturnToPool(AAcidProjectile Projectile)
	{
		PooledProjectiles.Add(Projectile);
		Projectile.AddActorDisable(this);
		Projectiles.RemoveSingle(Projectile);
	}

	AAcidPuddle SpawnPuddle(FAcidPuddleParams Params)
	{
		return nullptr;
		// AAcidPuddle Puddle;
		// if (PooledPuddles.Num() != 0)
		// {
		// 	Puddle = PooledPuddles[0];
		// 	PooledPuddles.RemoveAt(0);
		// 	Puddle.RemoveActorDisable(this);
		// }
		// else
		// {
		// 	Puddle = SpawnActor(Params.PuddleClass);
		// 	Puddle.AcidManager = this;
		// }

		// Puddle.Init(Params);
		// AddPuddleToArea(Puddle);
		// return Puddle;
	}

	void ReturnToPool(AAcidPuddle Puddle)
	{
		RemovePuddleFromArea(Puddle);
		PooledPuddles.Add(Puddle);
		Puddle.AddActorDisable(this);
	}

	void AddPuddleToArea(AAcidPuddle Puddle)
	{
		// Check if it can fit inside an existing area
		float PuddleRadius = Puddle.PuddleParams.Radius;
		int BestArea = -1;
		float BestDistance = MAX_flt;

		for (int i = 0, Count = AcidAreas.Num(); i < Count; ++i)
		{
			FAcidAreaSphere& Area = AcidAreas[i];
			float Distance = Math::Max(Puddle.ActorLocation.Distance(Area.Location), 0.0);
			if (Distance < BestDistance)
			{
				BestArea = i;
				BestDistance = Distance;
			}
		}

		if (BestArea != -1 && (BestDistance + PuddleRadius) < AREA_MAX_SIZE)
		{
			FAcidAreaSphere& Area = AcidAreas[BestArea];
			Area.Radius = Math::Max(Area.Radius, BestDistance + PuddleRadius);
			Area.Puddles.Add(Puddle);
			Puddle.AcidAreaId = Area.AreaId;
			return;
		}

		// Create a new area for this puddle
		FAcidAreaSphere Area;
		Area.Location = Puddle.ActorLocation;
		Area.Radius = PuddleRadius;
		Area.AreaId = NextAreaId;
		NextAreaId++;
		Area.Puddles.Add(Puddle);

		AcidAreas.Add(Area);
	}

	void RemovePuddleFromArea(AAcidPuddle Puddle)
	{
		if (Puddle.AcidAreaId == -1)
			return;

		for (int i = AcidAreas.Num() - 1; i >= 0; --i)
		{
			FAcidAreaSphere& Area = AcidAreas[i];
			if (Area.AreaId != Puddle.AcidAreaId)
				continue;

			Area.Puddles.Remove(Puddle);
			break;
		}

		Puddle.AcidAreaId = -1;
	}

	bool IsAcidInsideShape(FHazeShapeSettings Shape, FTransform ShapeTransform)
	{
		float ShapeRadius = ShapeTransform.Scale3D.AbsMax * Shape.GetEncapsulatingSphereRadius();

		for (int i = AcidAreas.Num() - 1; i >= 0; --i)
		{
			FAcidAreaSphere& Area = AcidAreas[i];
			float Dist = Area.Location.Distance(ShapeTransform.Location);
			if (Dist > ShapeRadius + Area.Radius)
				continue;

			for (AAcidPuddle Puddle : Area.Puddles)
			{
				if (Shape.GetWorldDistanceToShape(ShapeTransform, Puddle.ActorLocation) < Puddle.PuddleParams.Radius)
					return true;
			}
		}

		return false;
	}
};