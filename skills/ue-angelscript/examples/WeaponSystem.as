// Example: Weapon system with firing, reloading, and ammo management
class AWeapon : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    USkeletalMeshComponent Mesh;
    
    UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Muzzle")
    USceneComponent MuzzlePoint;
    
    UPROPERTY(Category = "Weapon Stats")
    float Damage = 25.0f;
    
    UPROPERTY(Category = "Weapon Stats")
    float FireRate = 0.1f;
    
    UPROPERTY(Category = "Weapon Stats")
    int32 MaxAmmo = 30;
    
    UPROPERTY(Category = "Weapon Stats")
    int32 MaxReserveAmmo = 120;
    
    UPROPERTY(Replicated)
    int32 CurrentAmmo = 30;
    
    UPROPERTY(Replicated)
    int32 ReserveAmmo = 90;
    
    UPROPERTY()
    float LastFireTime = 0.0f;
    
    UPROPERTY()
    bool bIsReloading = false;
    
    UPROPERTY()
    TSubclassOf<AProjectile> ProjectileClass;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        CurrentAmmo = MaxAmmo;
    }
    
    UFUNCTION(BlueprintCallable)
    void Fire(FVector TargetLocation)
    {
        if (!CanFire())
            return;
            
        LastFireTime = GetWorld().TimeSeconds;
        CurrentAmmo--;
        
        FVector MuzzleLocation = MuzzlePoint.GetWorldLocation();
        FVector FireDirection = (TargetLocation - MuzzleLocation).GetSafeNormal();
        
        // Server RPC for authoritative firing
        if (HasAuthority())
        {
            Server_Fire(MuzzleLocation, FireDirection);
        }
        else
        {
            // Client-side prediction
            SpawnProjectile(MuzzleLocation, FireDirection);
            Server_Fire(MuzzleLocation, FireDirection);
        }
        
        // Play local effects
        PlayFireEffects();
    }
    
    UFUNCTION(Server, Reliable)
    void Server_Fire(FVector Location, FVector Direction)
    {
        if (!HasAuthority())
            return;
            
        SpawnProjectile(Location, Direction);
        Multicast_PlayFireEffects();
    }
    
    UFUNCTION()
    void SpawnProjectile(FVector Location, FVector Direction)
    {
        if (ProjectileClass == nullptr)
            return;
            
        FTransform SpawnTransform = FTransform(Direction.Rotation(), Location);
        AProjectile Projectile = Cast<AProjectile>(
            SpawnActor(ProjectileClass, SpawnTransform)
        );
        
        if (Projectile != nullptr)
        {
            Projectile.SetDamage(Damage);
            Projectile.SetOwner(GetOwner());
        }
    }
    
    UFUNCTION(NetMulticast, Reliable)
    void Multicast_PlayFireEffects()
    {
        PlayFireEffects();
    }
    
    UFUNCTION(BlueprintEvent)
    void PlayFireEffects();
    
    UFUNCTION(BlueprintCallable)
    bool CanFire() const
    {
        if (bIsReloading)
            return false;
        if (CurrentAmmo <= 0)
            return false;
        if (GetWorld().TimeSeconds - LastFireTime < FireRate)
            return false;
        return true;
    }
    
    UFUNCTION(BlueprintCallable)
    void StartReload()
    {
        if (bIsReloading || CurrentAmmo >= MaxAmmo || ReserveAmmo <= 0)
            return;
            
        bIsReloading = true;
        PlayReloadAnimation();
        
        // Simulate reload time
        float ReloadTime = 2.0f;
        System::SetTimer(this, n"FinishReload", ReloadTime, false);
    }
    
    UFUNCTION()
    void FinishReload()
    {
        if (!bIsReloading)
            return;
            
        int32 AmmoNeeded = MaxAmmo - CurrentAmmo;
        int32 AmmoToReload = FMath::Min(AmmoNeeded, ReserveAmmo);
        
        CurrentAmmo += AmmoToReload;
        ReserveAmmo -= AmmoToReload;
        bIsReloading = false;
        
        OnReloadComplete.Broadcast(CurrentAmmo, ReserveAmmo);
    }
    
    UFUNCTION(BlueprintEvent)
    void PlayReloadAnimation();
    
    UFUNCTION(BlueprintPure)
    bool NeedsReload() const
    {
        return CurrentAmmo == 0 || (float(CurrentAmmo) / float(MaxAmmo)) < 0.25f;
    }
    
    UFUNCTION(BlueprintCallable)
    void AddAmmo(int32 Amount)
    {
        ReserveAmmo = FMath::Min(ReserveAmmo + Amount, MaxReserveAmmo);
    }
    
    // Delegate for reload completion
delegate void FOnReloadComplete(int32 CurrentAmmo, int32 ReserveAmmo);
    FOnReloadComplete OnReloadComplete;
}
